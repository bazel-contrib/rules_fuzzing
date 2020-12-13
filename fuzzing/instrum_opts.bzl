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

# Instrumentation applied to all fuzz test executables when built in fuzzing
# mode. This mode is controlled by the `//fuzzing:cc_fuzzing_build_mode` config
# flag.
fuzzing_build_opts = instrumentation_opts(
    copts = ["-DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION"],
)

instrum_configs = {
    "none": instrum_opts.make(),
    "libfuzzer": instrum_defaults.libfuzzer,
    "honggfuzz": instrum_defaults.honggfuzz,
}

sanitizer_configs = {
    "none": instrum_opts.make(),
    "asan": instrum_defaults.asan,
    "msan": instrum_defaults.msan,
    "msan-origin-tracking": instrum_defaults.msan_origin_tracking,
}
