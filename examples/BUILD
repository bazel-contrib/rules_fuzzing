#
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

# Simple fuzz targets that demonstrate the Bazel extension functionality and serve as regression tests.

load("//fuzzing:cc_deps.bzl", "cc_fuzz_test")

cc_fuzz_test(
    name = "buffer_overflow_fuzz_test",
    srcs = ["buffer_overflow_fuzz_test.cc"],
)

cc_fuzz_test(
    name = "empty_fuzz_test",
    srcs = ["empty_fuzz_test.cc"],
)

cc_fuzz_test(
    name = "fuzzed_data_provider_fuzz_test",
    srcs = ["fuzzed_data_provider_fuzz_test.cc"],
    tags = ["FDP"],
)

cc_fuzz_test(
    name = "hang_fuzz_test",
    srcs = ["hang_fuzz_test.cc"],
)

# This test is designed to trigger an uninitialized memory issue
cc_fuzz_test(
    name = "msan_fuzz_test",
    srcs = ["msan_fuzz_test.cc"],
    copts = ["-Wno-uninitialized"],
)

cc_fuzz_test(
    name = "oom_fuzz_test",
    srcs = ["oom_fuzz_test.cc"],
)
