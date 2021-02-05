# Copyright 2021 Google LLC
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

"""Dependency initialization utilities."""

load("@rules_python//python:pip.bzl", "pip_install")
load("@rules_python//python:repositories.bzl", "py_repositories")
load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

def rules_fuzzing_init():
    py_repositories()
    pip_install(
        name = "fuzzing_py_deps",
        extra_pip_args = ["--require-hashes"],
        requirements = "@rules_fuzzing//fuzzing:requirements.txt",
    )
    bazel_skylib_workspace()
