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

"""The implementation of the {cc, java}_fuzz_test rules."""

load("@rules_cc//cc:defs.bzl", "cc_binary")

# FIXME: Including this leads to a Stardoc error since defs.bzl is not visible. As a workaround, use native.java_binary.
#load("@rules_java//java:defs.bzl", "java_binary")
load("//fuzzing/private:common.bzl", "fuzzing_corpus", "fuzzing_dictionary", "fuzzing_launcher")
load("//fuzzing/private:binary.bzl", "fuzzing_binary", "fuzzing_binary_uninstrumented")
load("//fuzzing/private:java_utils.bzl", "determine_primary_class", "jazzer_fuzz_binary")
load("//fuzzing/private:regression.bzl", "fuzzing_regression_test")
load("//fuzzing/private/oss_fuzz:package.bzl", "oss_fuzz_package")

def fuzzing_decoration(
        name,
        raw_binary,
        engine,
        corpus = None,
        dicts = None,
        instrument_binary = True,
        define_regression_test = True,
        test_size = None,
        test_tags = None,
        test_timeout = None):
    """Generates the standard targets associated to a fuzz test.

    This macro can be used to define custom fuzz test rules in case the default
    `cc_fuzz_test` macro is not adequate. Refer to the `cc_fuzz_test` macro
    documentation for the set of targets generated.

    Args:
        name: The name prefix of the generated targets. It is normally the
          fuzz test name in the BUILD file.
        raw_binary: The label of the cc_binary or cc_test of fuzz test
          executable.
        engine: The label of the fuzzing engine used to build the binary.
        corpus: A list of corpus files.
        dicts: A list of fuzzing dictionary files.
        instrument_binary: **(Experimental, may be removed in the future.)**

          By default, the generated targets depend on `raw_binary` through
          a Bazel configuration using flags from the `@rules_fuzzing//fuzzing`
          package to determine the fuzzing build mode, engine, and sanitizer
          instrumentation.

          When this argument is false, the targets assume that `raw_binary` is
          already built in the proper configuration and will not apply the
          transition.

          Most users should not need to change this argument. If you think the
          default instrumentation mode does not work for your use case, please
          file a Github issue to discuss.
        define_regression_test: If true, generate a regression test rule.
        test_size: The size of the fuzzing regression test.
        test_tags: Tags set on the fuzzing regression test.
        test_timeout: The timeout for the fuzzing regression test.
    """

    # We tag all non-test targets as "manual" in order to optimize the build
    # size output of test runs in RBE mode. Otherwise, "bazel test" commands
    # build all the non-test targets by default and, in remote builds, all these
    # targets and their runfiles would be transferred from the remote cache to
    # the local machine, ballooning the size of the output.

    instrum_binary_name = name + "_bin"
    launcher_name = name + "_run"
    corpus_name = name + "_corpus"
    dict_name = name + "_dict"

    if instrument_binary:
        fuzzing_binary(
            name = instrum_binary_name,
            binary = raw_binary,
            engine = engine,
            corpus = corpus_name,
            dictionary = dict_name if dicts else None,
            testonly = True,
            tags = ["manual"],
        )
    else:
        fuzzing_binary_uninstrumented(
            name = instrum_binary_name,
            binary = raw_binary,
            engine = engine,
            corpus = corpus_name,
            dictionary = dict_name if dicts else None,
            testonly = True,
            tags = ["manual"],
        )

    fuzzing_corpus(
        name = corpus_name,
        srcs = corpus,
        testonly = True,
    )

    if dicts:
        fuzzing_dictionary(
            name = dict_name,
            dicts = dicts,
            output = name + ".dict",
            testonly = True,
        )

    fuzzing_launcher(
        name = launcher_name,
        binary = instrum_binary_name,
        testonly = True,
        tags = ["manual"],
    )

    if define_regression_test:
        fuzzing_regression_test(
            name = name,
            binary = instrum_binary_name,
            size = test_size,
            tags = test_tags,
            timeout = test_timeout,
        )

    oss_fuzz_package(
        name = name + "_oss_fuzz",
        base_name = name,
        binary = instrum_binary_name,
        testonly = True,
        tags = ["manual"],
    )

def cc_fuzz_test(
        name,
        corpus = None,
        dicts = None,
        engine = "@rules_fuzzing//fuzzing:cc_engine",
        size = None,
        tags = None,
        timeout = None,
        **binary_kwargs):
    """Defines a C++ fuzz test and a few associated tools and metadata.

    For each fuzz test `<name>`, this macro defines a number of targets. The
    most relevant ones are:

    * `<name>`: A test that executes the fuzzer binary against the seed corpus
      (or on an empty input if no corpus is specified).
    * `<name>_bin`: The instrumented fuzz test executable. Use this target
      for debugging or for accessing the complete command line interface of the
      fuzzing engine. Most developers should only need to use this target
      rarely.
    * `<name>_run`: An executable target used to launch the fuzz test using a
      simpler, engine-agnostic command line interface.
    * `<name>_oss_fuzz`: Generates a `<name>_oss_fuzz.tar` archive containing
      the fuzz target executable and its associated resources (corpus,
      dictionary, etc.) in a format suitable for unpacking in the $OUT/
      directory of an OSS-Fuzz build. This target can be used inside the
      `build.sh` script of an OSS-Fuzz project.

    Args:
        name: A unique name for this target. Required.
        corpus: A list containing corpus files.
        dicts: A list containing dictionaries.
        engine: A label pointing to the fuzzing engine to use.
        size: The size of the regression test. This does *not* affect fuzzing
          itself. Takes the [common size values](https://bazel.build/reference/be/common-definitions#test.size).
        tags: Tags set on the regression test.
        timeout: The timeout for the regression test. This does *not* affect
          fuzzing itself. Takes the [common timeout values](https://docs.bazel.build/versions/main/be/common-definitions.html#test.timeout).
        **binary_kwargs: Keyword arguments directly forwarded to the fuzz test
          binary rule.
    """

    # Append the '_' suffix to the raw target to dissuade users from referencing
    # this target directly. Instead, the binary should be built through the
    # instrumented configuration.
    raw_binary_name = name + "_raw_"
    binary_kwargs.setdefault("deps", [])

    # Use += rather than append to allow users to pass in select() expressions for
    # deps, which only support concatenation with +.
    # Workaround for https://github.com/bazelbuild/bazel/issues/14157.
    # buildifier: disable=list-append
    binary_kwargs["deps"] += [engine]

    # tags is not configurable and can thus use append.
    binary_kwargs.setdefault("tags", []).append("manual")
    cc_binary(
        name = raw_binary_name,
        **binary_kwargs
    )

    fuzzing_decoration(
        name = name,
        raw_binary = raw_binary_name,
        engine = engine,
        corpus = corpus,
        dicts = dicts,
        test_size = size,
        test_tags = (tags or []) + [
            "fuzz-test",
        ],
        test_timeout = timeout,
    )

def java_fuzz_test(
        name,
        srcs = None,
        target_class = None,
        corpus = None,
        dicts = None,
        engine = "@rules_fuzzing//fuzzing:java_engine",
        size = None,
        tags = None,
        timeout = None,
        **binary_kwargs):
    """Defines a Java fuzz test and a few associated tools and metadata.

    For each fuzz test `<name>`, this macro defines a number of targets. The
    most relevant ones are:

    * `<name>`: A test that executes the fuzzer binary against the seed corpus
      (or on an empty input if no corpus is specified).
    * `<name>_bin`: The instrumented fuzz test executable. Use this target
      for debugging or for accessing the complete command line interface of the
      fuzzing engine. Most developers should only need to use this target
      rarely.
    * `<name>_run`: An executable target used to launch the fuzz test using a
      simpler, engine-agnostic command line interface.
    * `<name>_oss_fuzz`: Generates a `<name>_oss_fuzz.tar` archive containing
      the fuzz target executable and its associated resources (corpus,
      dictionary, etc.) in a format suitable for unpacking in the $OUT/
      directory of an OSS-Fuzz build. This target can be used inside the
      `build.sh` script of an OSS-Fuzz project.

    Args:
        name: A unique name for this target. Required.
        srcs: A list of source files of the target.
        target_class: The class that contains the static fuzzerTestOneInput
          method. Defaults to the same class main_class would.
        corpus: A list containing corpus files.
        dicts: A list containing dictionaries.
        engine: A label pointing to the fuzzing engine to use.
        size: The size of the regression test. This does *not* affect fuzzing
          itself. Takes the [common size values](https://bazel.build/reference/be/common-definitions#test.size).
        tags: Tags set on the regression test.
        timeout: The timeout for the regression test. This does *not* affect
          fuzzing itself. Takes the [common timeout values](https://docs.bazel.build/versions/main/be/common-definitions.html#test.timeout).
        **binary_kwargs: Keyword arguments directly forwarded to the fuzz test
          binary rule.
    """

    # Append the '_' suffix to the raw target to dissuade users from referencing
    # this target directly. Instead, the binary should be built through the
    # instrumented configuration.
    raw_target_name = name + "_target_"

    # Determine a value for target_class heuristically using the same rules as
    # those used by Bazel internally for main_class.
    # FIXME: This operates on the raw unresolved srcs list entries and thus
    #  cannot handle labels.
    if not target_class:
        target_class = determine_primary_class(srcs, name)
    if not target_class:
        fail(("Unable to determine fuzz target class for java_fuzz_test {name}" +
              ", specify target_class.").format(
            name = name,
        ))
    target_class_manifest_line = "Jazzer-Fuzz-Target-Class: %s" % target_class
    binary_kwargs.setdefault("deps", [])

    # Use += rather than append to allow users to pass in select() expressions for
    # deps, which only support concatenation with +.
    # Workaround for https://github.com/bazelbuild/bazel/issues/14157.
    # buildifier: disable=list-append
    binary_kwargs["deps"] += [engine]
    binary_kwargs.setdefault("deploy_manifest_lines", [])

    # buildifier: disable=list-append
    binary_kwargs["deploy_manifest_lines"] += [target_class_manifest_line]

    # tags is not configurable and can thus use append.
    binary_kwargs.setdefault("tags", []).append("manual")
    native.java_binary(
        name = raw_target_name,
        srcs = srcs,
        create_executable = False,
        **binary_kwargs
    )

    raw_binary_name = name + "_raw_"
    jazzer_fuzz_binary(
        name = raw_binary_name,
        agent = select({
            "@rules_fuzzing//fuzzing/private:use_oss_fuzz": "@rules_fuzzing_oss_fuzz//:jazzer_agent_deploy.jar",
            "//conditions:default": "@jazzer//agent:jazzer_agent_deploy.jar",
        }),
        # Since the choice of sanitizer is explicit for local fuzzing, we also
        # let it apply to projects with no native dependencies.
        driver_java_only = select({
            "@rules_fuzzing//fuzzing/private:use_oss_fuzz": "@rules_fuzzing_oss_fuzz//:jazzer_driver",
            "@rules_fuzzing//fuzzing/private:use_sanitizer_none": "@jazzer//driver:jazzer_driver",
            "@rules_fuzzing//fuzzing/private:use_sanitizer_asan": "@jazzer//driver:jazzer_driver_asan",
            "@rules_fuzzing//fuzzing/private:use_sanitizer_ubsan": "@jazzer//driver:jazzer_driver_ubsan",
        }, no_match_error = "Jazzer only supports the sanitizer settings: \"none\", \"asan\", \"ubsan\""),
        driver_with_native = select({
            "@rules_fuzzing//fuzzing/private:use_oss_fuzz": "@rules_fuzzing_oss_fuzz//:jazzer_driver_with_sanitizer",
            "@rules_fuzzing//fuzzing/private:use_sanitizer_none": "@jazzer//driver:jazzer_driver",
            "@rules_fuzzing//fuzzing/private:use_sanitizer_asan": "@jazzer//driver:jazzer_driver_asan",
            "@rules_fuzzing//fuzzing/private:use_sanitizer_ubsan": "@jazzer//driver:jazzer_driver_ubsan",
        }, no_match_error = "Jazzer only supports the sanitizer settings: \"none\", \"asan\", \"ubsan\""),
        sanitizer_options = select({
            "@rules_fuzzing//fuzzing/private:use_oss_fuzz": "@rules_fuzzing//fuzzing/private:oss_fuzz_jazzer_sanitizer_options.sh",
            "//conditions:default": "@rules_fuzzing//fuzzing/private:local_jazzer_sanitizer_options.sh",
        }),
        tags = ["manual"],
        target = raw_target_name,
        target_deploy_jar = raw_target_name + "_deploy.jar",
    )

    fuzzing_decoration(
        name = name,
        raw_binary = raw_binary_name,
        # jazzer_fuzz_binary already instrumented the native dependencies.
        instrument_binary = False,
        engine = engine,
        corpus = corpus,
        dicts = dicts,
        test_size = size,
        test_tags = (tags or []) + [
            "fuzz-test",
        ],
        test_timeout = timeout,
    )
