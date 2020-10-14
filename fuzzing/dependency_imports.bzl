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

# Loads the dependencies of the external repositories

load("@rules_python//python:pip.bzl", "pip3_import", "pip_repositories")
load("@rules_python//python:repositories.bzl", "py_repositories")
load("@rules_pkg//:deps.bzl", "rules_pkg_dependencies")
load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

def fuzzing_dependency_imports():
    """Imports the dependencies of the external repositories."""
    py_repositories()
    rules_pkg_dependencies()
    bazel_skylib_workspace()
    pip_repositories()

    pip3_import(
        name = "fuzzing_py_deps",
        requirements = "@rules_fuzzing//fuzzing:requirements.txt",
    )
