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
load("@rules_pkg//:pkg.bzl", "pkg_zip")
load("//fuzzing/private:common.bzl", "fuzzing_corpus", "fuzzing_dictionary", "fuzzing_launcher")

def cc_fuzz_test(
        name,
        corpus = None,
        dicts = None,
        **binary_kwargs):
    """Macro for c++ fuzzing test

    This macro provides below targets:
    <name>: the executable file built by cc_test.
    <name>_run: an executable to launch the fuzz test.
    <name>_corpus: a target to generate a directory containing all corpus files if the argument corpus is passed.
    <name>_corpus_zip: an target to generate a zip file containing corpus files if the argument corpus is passed.

    Args:
        name: A unique name for this target. Required.
        corpus: A list containing corpus files.
        dicts: A list containing dictionaries.
        **binary_kwargs: Keyword arguments directly forwarded to the fuzz test binary rule.
    """

    binary_kwargs.setdefault("tags", []).append("fuzz-test")
    binary_kwargs.setdefault("deps", []).append("//fuzzing:cc_engine")
    cc_test(
        name = name,
        **binary_kwargs
    )

    if corpus:
        fuzzing_corpus(
            name = name + "_corpus",
            srcs = corpus,
        )
        pkg_zip(
            name = name + "_corpus_zip",
            srcs = [name + "_corpus"],
        )
    if dicts:
        fuzzing_dictionary(
            name = name + "_dict",
            dicts = dicts,
            output = name + ".dict",
        )

    fuzzing_launcher(
        name = name + "_run",
        engine = "//fuzzing:cc_engine",
        binary = name,
        corpus = name + "_corpus" if corpus else None,
        dictionary = name + "_dict" if dicts else None,
        # Since the script depends on the _fuzz_test above, which is a cc_test,
        # this attribute must be set.
        testonly = True,
    )
