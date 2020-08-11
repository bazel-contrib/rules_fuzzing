#
#  Copyright 2020 Google LLC
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

"""This file contains basic functions for cc fuzz test."""

load("@rules_cc//cc:defs.bzl", "cc_test")
load("@rules_pkg//:pkg.bzl", "pkg_zip")
load("//fuzzing:common.bzl", "fuzzing_corpus", "fuzzing_launcher")

def cc_fuzz_test(
        name,
        corpus = None,
        **kwargs):
    """Macro for c++ fuzzing test

    This macro provides two targets:
    <name>: the executable file built by cc_test.
    <name>_run: an executable to launch the fuzz test.
"""

    # Add fuzz_test tag
    kwargs.setdefault("tags", []).append("fuzz_test")

    cc_test(
        name = name,
        **kwargs
    )

    if corpus:
        corpus_list = native.glob(corpus)
        fuzzing_corpus(
            name = name + "_corpus",
            srcs = corpus_list,
        )
        pkg_zip(
            name = name + "_corpus_zip",
            srcs = corpus_list,
        )

    fuzzing_launcher(
        name = name + "_run",
        target = name,
        corpus = name + "_corpus" if corpus else None,
        is_regression = False,
        # Since the script depends on the _fuzz_test above, which is a cc_test,
        # this attribute must be set.
        testonly = True,
    )
