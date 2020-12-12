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

"""Fuzz test instrumentation options.

Each fuzzing engine or sanitizer instrumentation recognized by the
//fuzzing:cc_engine_instrumentation and //fuzzing:cc_engine_sanitizer
configuration flag should be defined here.
"""

def _is_string_list(value):
    if type(value) != type([]):
        return False
    if any([type(element) != type("") for element in value]):
        return False
    return True

def instrumentation_opts(
        copts = [],
        conlyopts = [],
        cxxopts = [],
        linkopts = []):
    """Creates new instrumentation options.

    The struct fields mirror the argument names of this function.

    Args:
      copts: A list of C/C++ compilation options passed as `--copt`
        configuration flags.
      conlyopts: A list of C-only compilation options passed as `--conlyopt`
        configuration flags.
      cxxopts: A list of C++-only compilation options passed as `--cxxopts`
        configuration flags.
      linkopts: A list of linker options to pass as `--linkopt`
        configuration flags.
    Returns:
      A struct with the given instrumentation options.
    """
    if not _is_string_list(copts):
        fail("copts should be a list of strings")
    if not _is_string_list(conlyopts):
        fail("conlyopts should be a list of strings")
    if not _is_string_list(cxxopts):
        fail("cxxopts should be a list of strings")
    if not _is_string_list(linkopts):
        fail("linkopts should be a list of strings")
    return struct(
        copts = copts,
        conlyopts = conlyopts,
        cxxopts = cxxopts,
        linkopts = linkopts,
    )

# Instrumentation applied to all fuzz test executables when built in fuzzing
# mode. This mode is controlled by the `//fuzzing:cc_fuzzing_build_mode` config
# flag.
fuzzing_build_opts = instrumentation_opts(
    copts = ["-DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION"],
)

# Engine-specific instrumentation.
fuzzing_engine_opts = {
    "none": instrumentation_opts(),
    "libfuzzer": instrumentation_opts(
        copts = ["-fsanitize=fuzzer-no-link"],
    ),
    # Reflects the set of options at
    # https://github.com/google/honggfuzz/blob/master/hfuzz_cc/hfuzz-cc.c
    "honggfuzz": instrumentation_opts(
        copts = [
            "-mllvm",
            "-inline-threshold=2000",
            "-fno-builtin",
            "-fno-omit-frame-pointer",
            "-D__NO_STRING_INLINES",
            "-fsanitize-coverage=trace-pc-guard,trace-cmp,trace-div,indirect-calls",
            "-fno-sanitize=fuzzer",
        ],
        linkopts = [
            "-fno-sanitize=fuzzer",
        ],
    ),
}

# Sanitizer-specific instrumentation.
sanitizer_opts = {
    "none": instrumentation_opts(),
    "asan": instrumentation_opts(
        copts = ["-fsanitize=address"],
        linkopts = ["-fsanitize=address"],
    ),
    "msan": instrumentation_opts(
        copts = ["-fsanitize=memory"],
        linkopts = ["-fsanitize=memory"],
    ),
    "msan-origin-tracking": instrumentation_opts(
        copts = [
            "-fsanitize=memory",
            "-fsanitize-memory-track-origins=2",
        ],
        linkopts = ["-fsanitize=memory"],
    ),
}
