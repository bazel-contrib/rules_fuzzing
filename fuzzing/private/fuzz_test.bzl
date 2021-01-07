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
load("//fuzzing/private:binary.bzl", "fuzzing_binary")
load("//fuzzing/private:regression.bzl", "fuzzing_regression_test")
load("//fuzzing/private/oss_fuzz:package.bzl", "oss_fuzz_package")

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
    * `<name>_instrum`: The instrumented fuzz test executable. Use this target
      for debugging or for accessing the complete command line interface of the
      fuzzing engine. Most developers should only need to use this target
      rarely.
    * `<name>_run`: An executable target used to launch the fuzz test using a
      simpler, engine-agnostic command line interface.

    > TODO: Document here the command line interface of the `<name>_run`
    targets.

    Args:
        name: A unique name for this target. Required.
        corpus: A list containing corpus files.
        dicts: A list containing dictionaries.
        engine: A label pointing to the fuzzing engine to use.
        tags: Tags set on the fuzz test executable.
        **binary_kwargs: Keyword arguments directly forwarded to the fuzz test
          binary rule.
    """

    raw_binary_name = name + "_raw_"
    instrum_binary_name = name + "_instrum"
    launcher_name = name + "_run"
    corpus_name = name + "_corpus"

    binary_kwargs.setdefault("deps", []).append(engine)
    cc_binary(
        name = raw_binary_name,
        **binary_kwargs
    )

    fuzzing_binary(
        name = instrum_binary_name,
        binary = raw_binary_name,
        engine = engine,
        corpus = corpus_name,
        dictionary = name + "_dict" if dicts else None,
    )

    fuzzing_corpus(
        name = corpus_name,
        srcs = corpus,
    )
    if dicts:
        fuzzing_dictionary(
            name = name + "_dict",
            dicts = dicts,
            output = name + ".dict",
        )

    fuzzing_launcher(
        name = launcher_name,
        binary = instrum_binary_name,
    )

    fuzzing_regression_test(
        name = name,
        binary = instrum_binary_name,
        tags = (tags or []) + [
            "fuzz-test",
        ],
    )

    oss_fuzz_package(
        name = name + "_oss_fuzz",
        binary = instrum_binary_name,
        testonly = True,
    )
