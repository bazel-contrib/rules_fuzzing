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

"""The implementation of the cc_fuzz_test rule."""

load("@rules_cc//cc:defs.bzl", "cc_binary")
load("//fuzzing/private:common.bzl", "fuzzing_corpus", "fuzzing_dictionary", "fuzzing_launcher")
load("//fuzzing/private:binary.bzl", "fuzzing_binary", "fuzzing_binary_uninstrumented")
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
        test_tags = None):
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
        test_tags: Tags set on the fuzzing regression test.
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
            tags = test_tags,
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
        tags = None,
        **binary_kwargs):
    """Defines a fuzz test and a few associated tools and metadata.

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
        tags: Tags set on the fuzzing regression test.
        **binary_kwargs: Keyword arguments directly forwarded to the fuzz test
          binary rule.
    """

    # Append the '_' suffix to the raw target to dissuade users from referencing
    # this target directly. Instead, the binary should be built through the
    # instrumented configuration.
    raw_binary_name = name + "_raw_"
    binary_kwargs.setdefault("deps", []).append(engine)
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
        test_tags = (tags or []) + [
            "fuzz-test",
        ],
    )
