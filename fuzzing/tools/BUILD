#
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

# This package contains tool scripts

load("@rules_python//python:defs.bzl", "py_binary", "py_library", "py_test")

py_binary(
    name = "launcher",
    srcs = ["launcher.py"],
    visibility = ["//visibility:public"],
)

py_library(
    name = "dict_validator_lib",
    srcs = ["dict_validator.py"],
    visibility = ["//visibility:public"],
)

py_binary(
    name = "dict_validator",
    srcs = ["dict_validator.py"],
    visibility = ["//visibility:public"],
)

py_test(
    name = "dict_validator_test",
    srcs = ["dict_validator_test.py"],
    data = [
        "dict_data/invalid.dict",
        "dict_data/valid.dict",
    ],
    deps = [":dict_validator_lib"],
)
