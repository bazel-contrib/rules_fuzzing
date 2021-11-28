# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load(":engine_test.bzl", "engine_test_suite")

engine_test_suite(
    name = "engine_test",
)

exports_files([
    "binary.bzl",
    "common.bzl",
    "engine.bzl",
    "fuzz_test.bzl",
    "instrum_opts.bzl",
    "java_utils.bzl",
    "regression.bzl",
    "util.bzl",
])

# Config settings needed for prebuilt engines.
config_setting(
    name = "use_sanitizer_none",
    flag_values = {
        "@rules_fuzzing//fuzzing:cc_engine_sanitizer": "none",
    },
)

config_setting(
    name = "use_sanitizer_asan",
    flag_values = {
        "@rules_fuzzing//fuzzing:cc_engine_sanitizer": "asan",
    },
)

config_setting(
    name = "use_sanitizer_ubsan",
    flag_values = {
        "@rules_fuzzing//fuzzing:cc_engine_sanitizer": "ubsan",
    },
)

config_setting(
    name = "use_oss_fuzz",
    flag_values = {
        "@rules_fuzzing//fuzzing:cc_engine": "@rules_fuzzing_oss_fuzz//:oss_fuzz_engine",
        # This is required to make the setting an unambiguous specialization of
        # the use_sanitizer_* settings.
        "@rules_fuzzing//fuzzing:cc_engine_sanitizer": "none",
    },
)

exports_files([
    "local_jazzer_sanitizer_options.sh",
    "oss_fuzz_jazzer_sanitizer_options.sh",
])
