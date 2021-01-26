# Copyright 2020 Google LLC
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

"""Defines a rule for creating an instrumented fuzzing executable."""

load("//fuzzing/private:engine.bzl", "CcFuzzingEngineInfo")
load(
    "//fuzzing/private:instrum_opts.bzl",
    "instrum_defaults",
    "instrum_opts",
)
load(
    "//fuzzing:instrum_opts.bzl",
    "instrum_configs",
    "sanitizer_configs",
)

CcFuzzingBinaryInfo = provider(
    doc = """
Provider for storing information about a fuzz test binary.
""",
    fields = {
        "binary_file": "The instrumented fuzz test executable.",
        "binary_runfiles": "The runfiles of the fuzz test executable.",
        "corpus_dir": "The directory of the corpus files used as input seeds.",
        "dictionary_file": "The dictionary file to use in fuzzing runs.",
        "engine_info": "The `CcFuzzingEngineInfo` provider of the fuzzing engine used in the fuzz test.",
    },
)

def _fuzzing_binary_transition_impl(settings, attr):
    opts = instrum_opts.make(
        copts = settings["//command_line_option:copt"],
        conlyopts = settings["//command_line_option:conlyopt"],
        cxxopts = settings["//command_line_option:cxxopt"],
        linkopts = settings["//command_line_option:linkopt"],
    )

    is_fuzzing_build_mode = settings["@rules_fuzzing//fuzzing:cc_fuzzing_build_mode"]
    if is_fuzzing_build_mode:
        opts = instrum_opts.merge(opts, instrum_defaults.fuzzing_build)

    instrum_config = settings["@rules_fuzzing//fuzzing:cc_engine_instrumentation"]
    if instrum_config in instrum_configs:
        opts = instrum_opts.merge(opts, instrum_configs[instrum_config])
    else:
        fail("unsupported engine instrumentation '%s'" % instrum_config)

    sanitizer_config = settings["@rules_fuzzing//fuzzing:cc_engine_sanitizer"]
    if sanitizer_config in sanitizer_configs:
        opts = instrum_opts.merge(opts, sanitizer_configs[sanitizer_config])
    else:
        fail("unsupported sanitizer '%s'" % sanitizer_config)

    return {
        "//command_line_option:copt": opts.copts,
        "//command_line_option:linkopt": opts.linkopts,
        "//command_line_option:conlyopt": opts.conlyopts,
        "//command_line_option:cxxopt": opts.cxxopts,
        # Make sure binaries are built statically, to maximize the scope of the
        # instrumentation.
        "//command_line_option:dynamic_mode": "off",
    }

fuzzing_binary_transition = transition(
    implementation = _fuzzing_binary_transition_impl,
    inputs = [
        "@rules_fuzzing//fuzzing:cc_engine_instrumentation",
        "@rules_fuzzing//fuzzing:cc_engine_sanitizer",
        "@rules_fuzzing//fuzzing:cc_fuzzing_build_mode",
        "//command_line_option:copt",
        "//command_line_option:conlyopt",
        "//command_line_option:cxxopt",
        "//command_line_option:linkopt",
    ],
    outputs = [
        "//command_line_option:copt",
        "//command_line_option:conlyopt",
        "//command_line_option:cxxopt",
        "//command_line_option:linkopt",
        "//command_line_option:dynamic_mode",
    ],
)

def _fuzzing_binary_impl(ctx):
    output_file = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(
        output = output_file,
        target_file = ctx.executable.binary,
        is_executable = True,
    )
    if ctx.attr._instrument_binary:
        # The attribute is a list if a transition is attached.
        binary_runfiles = ctx.attr.binary[0][DefaultInfo].default_runfiles
    else:
        binary_runfiles = ctx.attr.binary[DefaultInfo].default_runfiles
    other_runfiles = []
    if ctx.file.corpus:
        other_runfiles.append(ctx.file.corpus)
    if ctx.file.dictionary:
        other_runfiles.append(ctx.file.dictionary)
    return [
        DefaultInfo(
            executable = output_file,
            runfiles = binary_runfiles.merge(ctx.runfiles(files = other_runfiles)),
        ),
        CcFuzzingBinaryInfo(
            binary_file = ctx.executable.binary,
            binary_runfiles = binary_runfiles,
            corpus_dir = ctx.file.corpus,
            dictionary_file = ctx.file.dictionary,
            engine_info = ctx.attr.engine[CcFuzzingEngineInfo],
        ),
    ]

fuzzing_binary = rule(
    implementation = _fuzzing_binary_impl,
    doc = """
Creates an instrumented fuzzing executable.

The executable runfiles include the corpus directory and the dictionary file,
if specified.

The instrumentation is controlled by the following flags:

 * `@rules_fuzzing//fuzzing:cc_engine_instrumentation`
 * `@rules_fuzzing//fuzzing:cc_engine_sanitizer`
 * `@rules_fuzzing//fuzzing:cc_fuzzing_build_mode`
""",
    attrs = {
        "binary": attr.label(
            executable = True,
            doc = "The fuzz test executable to instrument.",
            cfg = fuzzing_binary_transition,
            mandatory = True,
        ),
        "engine": attr.label(
            doc = "The specification of the fuzzing engine used in the binary.",
            providers = [CcFuzzingEngineInfo],
            mandatory = True,
        ),
        "corpus": attr.label(
            doc = "A directory of corpus files used as input seeds.",
            allow_single_file = True,
        ),
        "dictionary": attr.label(
            doc = "A dictionary file to use in fuzzing runs.",
            allow_single_file = True,
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        "_instrument_binary": attr.bool(
            default = True,
        ),
    },
    executable = True,
    provides = [CcFuzzingBinaryInfo],
)

fuzzing_binary_uninstrumented = rule(
    implementation = _fuzzing_binary_impl,
    doc = """
Creates an uninstrumented fuzzing executable.

The fuzz test still requires instrumentation to function correctly, so it should
be incorporated in the target configuration (e.g., on the command line or the
.bazelrc configuration file).
""",
    attrs = {
        "binary": attr.label(
            executable = True,
            doc = "The instrumented fuzz test executable.",
            cfg = "target",
            mandatory = True,
        ),
        "engine": attr.label(
            doc = "The specification of the fuzzing engine used in the binary.",
            providers = [CcFuzzingEngineInfo],
            mandatory = True,
        ),
        "corpus": attr.label(
            doc = "A directory of corpus files used as input seeds.",
            allow_single_file = True,
        ),
        "dictionary": attr.label(
            doc = "A dictionary file to use in fuzzing runs.",
            allow_single_file = True,
        ),
        "_instrument_binary": attr.bool(
            default = False,
        ),
    },
    executable = True,
    provides = [CcFuzzingBinaryInfo],
)
