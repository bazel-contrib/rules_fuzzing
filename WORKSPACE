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

workspace(name = "rules_fuzzing")

load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

# Downloads dependencies.
load("@rules_fuzzing//fuzzing:repositories.bzl", "rules_fuzzing_dependencies")

rules_fuzzing_dependencies()

# Imports the transitive dependencies.
load("@rules_fuzzing//fuzzing:dependency_imports.bzl", "fuzzing_dependency_imports")

fuzzing_dependency_imports()

# Installs python dependencies.
load("@fuzzing_py_deps//:requirements.bzl", fuzzing_py_install = "pip_install")

fuzzing_py_install()

git_repository(
    name = "io_bazel_stardoc",
    commit = "4378e9b6bb2831de7143580594782f538f461180",
    remote = "https://github.com/bazelbuild/stardoc.git",
    shallow_since = "1570829166 -0400",
)

load("@io_bazel_stardoc//:setup.bzl", "stardoc_repositories")

stardoc_repositories()
