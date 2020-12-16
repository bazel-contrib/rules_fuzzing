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

load("@rules_cc//cc:defs.bzl", "cc_test")
load("//fuzzing/private:common.bzl", "fuzzing_corpus", "fuzzing_dictionary", "fuzzing_launcher")
load("//fuzzing/private:instrument.bzl", "instrumented_fuzzing_binary")

def cc_fuzz_test(
        name,
        corpus = None,
        dicts = None,
        engine = "@rules_fuzzing//fuzzing:cc_engine",
        tags = None,
        **binary_kwargs):
    """Defines a fuzz test and a few associated tools and metadata.

    For each fuzz test `<name>`, this macro expands into a number of targets:

    * `<name>`: The instrumented fuzz test executable. Use this target for
      debugging or for accessing the complete command line interface of the
      fuzzing engine. Most developers should only need to use this target
      rarely.
    * `<name>_run`: An executable target used to launch the fuzz test using a
      simpler, engine-agnostic command line interface.
    * `<name>_corpus`: Generates a corpus directory containing all the corpus
      files specified in the `corpus` attribute.
    * `<name>_dict`: Validates the set of dictionary files provided and emits
      the result to a `<name>.dict` file.
    * `<name>_raw`: The raw, uninstrumented fuzz test executable. This should be
      rarely needed and may be useful when debugging instrumentation-related
      build failures or misbehavior.

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

    binary_kwargs.setdefault("deps", []).append(engine)
    cc_test(
        name = name + "_raw",
        tags = [
            "manual",
        ],
        **binary_kwargs
    )

    instrumented_fuzzing_binary(
        name = name,
        binary = name + "_raw",
        tags = (tags or []) + [
            "fuzz-test",
        ],
        testonly = True,
    )

    if corpus:
        fuzzing_corpus(
            name = name + "_corpus",
            srcs = corpus,
        )
    if dicts:
        fuzzing_dictionary(
            name = name + "_dict",
            dicts = dicts,
            output = name + ".dict",
        )

    fuzzing_launcher(
        name = name + "_run",
        engine = engine,
        binary = name,
        corpus = name + "_corpus" if corpus else None,
        dictionary = name + "_dict" if dicts else None,
        # Since the script depends on the _fuzz_test above, which is a cc_test,
        # this attribute must be set.
        testonly = True,
    )
