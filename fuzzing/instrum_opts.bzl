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

load(
    "@rules_fuzzing//fuzzing/private:instrum_opts.bzl",
    "instrum_defaults",
    "instrum_opts",
)
load(
    "@rules_fuzzing_oss_fuzz//:instrum.bzl",
    "oss_fuzz_opts",
)

# Fuzz test binary instrumentation configurations by compiler type.
instrum_configs = {
    "clang": {
        "none": instrum_opts.make(),
        "libfuzzer": instrum_defaults.libfuzzer,
        "jazzer": instrum_defaults.jazzer,
        "honggfuzz": instrum_defaults.honggfuzz_clang,
        "oss-fuzz": oss_fuzz_opts,
    },
    "gcc": {
        "none": instrum_opts.make(),
        "honggfuzz": instrum_defaults.honggfuzz_gcc,
    },
}

# Sanitizer configurations by compiler type.
sanitizer_configs = {
    "clang": {
        "none": instrum_opts.make(),
        "asan": instrum_defaults.asan,
        "msan": instrum_defaults.msan,
        "msan-origin-tracking": instrum_defaults.msan_origin_tracking,
        "ubsan": instrum_defaults.ubsan_clang,
        "asan-ubsan": instrum_opts.merge(instrum_defaults.asan, instrum_defaults.ubsan_clang),
    },
    "gcc": {
        "none": instrum_opts.make(),
        "asan": instrum_defaults.asan,
        "ubsan": instrum_defaults.ubsan_gcc,
        "asan-ubsan": instrum_opts.merge(instrum_defaults.asan, instrum_defaults.ubsan_gcc),
    },
}
