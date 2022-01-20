# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Utilities and helper rules for Java fuzz tests."""

load("//fuzzing/private:binary.bzl", "fuzzing_binary_transition")
load("//fuzzing/private:util.bzl", "runfile_path")

# A Starlark reimplementation of a part of Bazel's JavaCommon#determinePrimaryClass.
def determine_primary_class(srcs, name):
    main_source_path = _get_java_main_source_path(srcs, name)
    return _get_java_full_classname(main_source_path)

# A Starlark reimplementation of a part of Bazel's JavaCommon#determinePrimaryClass.
def _get_java_main_source_path(srcs, name):
    main_source_basename = name + ".java"
    for source_file in srcs:
        if source_file[source_file.rfind("/") + 1:] == main_source_basename:
            main_source_basename = source_file
            break
    return native.package_name() + "/" + main_source_basename[:-len(".java")]

# A Starlark reimplementation of Bazel's JavaUtil#getJavaFullClassname.
def _get_java_full_classname(main_source_path):
    java_path = _get_java_path(main_source_path)
    if java_path != None:
        return java_path.replace("/", ".")
    return None

# A Starlark reimplementation of Bazel's JavaUtil#getJavaPath.
def _get_java_path(main_source_path):
    path_segments = main_source_path.split("/")
    index = _java_segment_index(path_segments)
    if index >= 0:
        return "/".join(path_segments[index + 1:])
    return None

_KNOWN_SOURCE_ROOTS = ["java", "javatests", "src", "testsrc"]

# A Starlark reimplementation of Bazel's JavaUtil#javaSegmentIndex.
def _java_segment_index(path_segments):
    root_index = -1
    for pos, segment in enumerate(path_segments):
        if segment in _KNOWN_SOURCE_ROOTS:
            root_index = pos
            break
    if root_index == -1:
        return root_index

    is_src = "src" == path_segments[root_index]
    check_maven_index = root_index if is_src else -1
    max = len(path_segments) - 1
    if root_index == 0 or is_src:
        for i in range(root_index + 1, max):
            segment = path_segments[i]
            if "src" == segment or (is_src and ("javatests" == segment or "java" == segment)):
                next = path_segments[i + 1]
                if ("com" == next or "org" == next or "net" == next):
                    root_index = i
                elif "src" == segment:
                    check_maven_index = i
                break

    if check_maven_index >= 0 and check_maven_index + 2 < len(path_segments):
        next = path_segments[check_maven_index + 1]
        if "main" == next or "test" == next:
            next = path_segments[check_maven_index + 2]
            if "java" == next or "resources" == next:
                root_index = check_maven_index + 2

    return root_index

def _jazzer_fuzz_binary_script(ctx, native_libs, driver):
    script = ctx.actions.declare_file(ctx.label.name)

    # The script is split into two parts: The first is emitted as-is, the second
    # is a template that is passed to format(). Without the split, curly braces
    # in the first part would need to be escaped.
    script_literal_part = """#!/bin/bash
# LLVMFuzzerTestOneInput - OSS-Fuzz needs this string literal to appear
# somewhere in the script so it is recognized as a fuzz target.

# Bazel-provided code snippet that should be copy-pasted as is at use sites.
# Taken from @bazel_tools//tools/bash/runfiles.
# --- begin runfiles.bash initialization v2 ---
# Copy-pasted from the Bazel Bash runfiles library v2.
set -uo pipefail; f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
source "$0.runfiles/$f" 2>/dev/null || \
source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
{ echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v2 ---

# Export the env variables required for subprocesses to find their runfiles.
runfiles_export_envvars

# When the runfiles tree exists but does not contain local_jdk, this script is
# executing on OSS-Fuzz. Link the current JAVA_HOME into the runfiles tree.
if [ -d "$0.runfiles" ] && [ ! -d "$0.runfiles/local_jdk" ]; then
    ln -s "$JAVA_HOME" "$0.runfiles/local_jdk"
fi
"""

    script_format_part = """
source "$(rlocation {sanitizer_options})"
exec "$(rlocation {driver})" \
    --agent_path="$(rlocation {agent})" \
    --cp="$(rlocation {deploy_jar})" \
    --jvm_args="-Djava.library.path={native_dirs}" \
    "$@"
"""

    native_dirs = [
        "$(dirname \"$(rlocation %s)\")" % runfile_path(ctx, lib)
        for lib in native_libs
    ]

    script_content = script_literal_part + script_format_part.format(
        agent = runfile_path(ctx, ctx.file.agent),
        deploy_jar = runfile_path(ctx, ctx.file.target_deploy_jar),
        driver = runfile_path(ctx, driver),
        # Jazzer requires the path separator to be escaped in --jvm_args.
        # See:
        # https://github.com/CodeIntelligenceTesting/jazzer#passing-jvm-arguments
        native_dirs = "\\:".join(native_dirs),
        sanitizer_options = runfile_path(ctx, ctx.file.sanitizer_options),
    )
    ctx.actions.write(script, script_content, is_executable = True)
    return script

def _is_required_runfile(runfile, runtime_classpath = []):
    # The jars in the runtime classpath are all merged into the deploy jar and
    # thus don't need to be included in the runfiles for the fuzzer.
    if runfile in runtime_classpath:
        return False

    # A java_binary target has a dependency on the local JDK. Since the Jazzer
    # driver launches its own JVM, these runfiles are not needed.
    if runfile.owner != None and runfile.owner.workspace_name == "local_jdk":
        return False
    return True

def _filter_target_runfiles(ctx, target):
    compilation_info = target[JavaInfo].compilation_info
    runtime_classpath = compilation_info.runtime_classpath.to_list()
    all_runfiles = target[DefaultInfo].default_runfiles
    return ctx.runfiles([
        runfile
        for runfile in all_runfiles.files.to_list()
        if _is_required_runfile(runfile, runtime_classpath)
    ])

def _is_potential_native_dependency(file):
    if file.extension not in ["dll", "dylib", "so"]:
        return False
    if not _is_required_runfile(file):
        return False
    return True

def _native_library_files(ctx):
    target_info = ctx.attr.target[0][DefaultInfo]
    target_java_info = ctx.attr.target[0][JavaInfo]

    # Perform feature detection for
    # https://github.com/bazelbuild/bazel/commit/381a519dfc082d4c62096c4ce77ead1c2e0410d8.
    if hasattr(target_java_info, "transitive_native_libraries"):
        # The current version of Bazel contains the commit, which means that
        # the JavaInfo of the target includes information about all transitive
        # native library dependencies.
        native_libraries_list = target_java_info.transitive_native_libraries.to_list()
        return [
            lib.dynamic_library
            for lib in native_libraries_list
            if lib.dynamic_library != None
        ]
    else:
        # If precise information about transitive native libraries is not
        # available, fall back to an overapproximation that includes all
        # runfiles with file extensions indicating a shared library.
        runfiles_list = target_info.default_runfiles.files.to_list()
        return [
            runfile
            for runfile in runfiles_list
            if _is_potential_native_dependency(runfile)
        ]

def _jazzer_fuzz_binary_impl(ctx):
    native_libs = _native_library_files(ctx)

    # Use a driver with a linked in sanitizer if the fuzz test has native
    # dependencies.
    if native_libs:
        driver = ctx.executable.driver_with_native
        driver_info = ctx.attr.driver_with_native[DefaultInfo]
    else:
        driver = ctx.executable.driver_java_only
        driver_info = ctx.attr.driver_java_only[DefaultInfo]

    # The DefaultInfo's default_runfiles of an executable file target do not
    # contain the executable itself, which thus needs to be added explicitly.
    driver_runfiles = driver_info.default_runfiles
    driver_executable = driver_info.files_to_run.executable
    driver_runfiles = driver_runfiles.merge(ctx.runfiles([driver_executable]))

    runfiles = ctx.runfiles()
    runfiles = runfiles.merge(driver_runfiles)

    # Used by the wrapper script created in _jazzer_fuzz_binary_script.
    runfiles = runfiles.merge(ctx.attr._bash_runfiles_library[DefaultInfo].default_runfiles)

    # While the Jazzer agent is already included in the runfiles of
    # @jazzer//driver:jazzer_driver, it has to be added here explicitly for the
    # case where both are provided by OSS-Fuzz.
    runfiles = runfiles.merge(ctx.runfiles([ctx.file.agent]))

    # The Java fuzz target packaged as a jar including all Java dependencies.
    # This does not include e.g. data runfiles and shared libraries.
    runfiles = runfiles.merge(ctx.runfiles([ctx.file.target_deploy_jar]))

    # The full runfiles of the Java fuzz target, but with the files of the local
    # JDK and all jar files excluded.
    runfiles = runfiles.merge(_filter_target_runfiles(ctx, ctx.attr.target[0]))

    runfiles = runfiles.merge(ctx.runfiles([ctx.file.sanitizer_options]))

    script = _jazzer_fuzz_binary_script(ctx, native_libs, driver)
    return [DefaultInfo(executable = script, runfiles = runfiles)]

jazzer_fuzz_binary = rule(
    implementation = _jazzer_fuzz_binary_impl,
    doc = """
Rule that creates a binary that invokes Jazzer on the specified target.
""",
    attrs = {
        "agent": attr.label(
            doc = "The Jazzer agent used to instrument the target.",
            allow_single_file = [".jar"],
        ),
        "_bash_runfiles_library": attr.label(
            default = "@bazel_tools//tools/bash/runfiles",
        ),
        "driver_java_only": attr.label(
            doc = "The Jazzer driver binary used to fuzz a Java-only target.",
            allow_single_file = True,
            executable = True,
            # Build in target configuration rather than host because the driver
            # uses transitions to set the correct C++ standard for its
            # dependencies.
            cfg = "target",
        ),
        "driver_with_native": attr.label(
            doc = "The Jazzer driver binary used to fuzz a Java target with " +
                  "native dependencies.",
            allow_single_file = True,
            executable = True,
            # Build in target configuration rather than host because the driver
            # uses transitions to set the correct C++ standard for its
            # dependencies.
            cfg = "target",
        ),
        "sanitizer_options": attr.label(
            doc = "A shell script that can export environment variables with " +
                  "sanitizer options.",
            allow_single_file = [".sh"],
        ),
        "target": attr.label(
            doc = "The fuzz target.",
            mandatory = True,
            providers = [JavaInfo],
            cfg = fuzzing_binary_transition,
        ),
        "target_deploy_jar": attr.label(
            doc = "The deploy jar of the fuzz target.",
            allow_single_file = [".jar"],
            mandatory = True,
            cfg = fuzzing_binary_transition,
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
    executable = True,
)
