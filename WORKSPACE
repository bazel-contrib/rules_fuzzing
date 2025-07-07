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

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# Load all external library dependencies.

load("@rules_fuzzing//fuzzing:repositories.bzl", "rules_fuzzing_dependencies")

rules_fuzzing_dependencies()

load("@rules_python//python:repositories.bzl", "py_repositories")

py_repositories()

load("@rules_fuzzing//fuzzing:init.bzl", "rules_fuzzing_init")

rules_fuzzing_init()

load("@fuzzing_py_deps//:requirements.bzl", "install_deps")

install_deps()

# The support for running the examples and unit tests.

http_archive(
    name = "re2",
    sha256 = "f89c61410a072e5cbcf8c27e3a778da7d6fd2f2b5b1445cd4f4508bee946ab0f",
    strip_prefix = "re2-2022-06-01",
    url = "https://github.com/google/re2/archive/2022-06-01.tar.gz",
)

http_archive(
    name = "com_google_googletest",
    integrity = "sha256-itWYxzrXluDYKAsILOvYKmMNc+c808cAV5OKZQG7pdc=",
    strip_prefix = "googletest-1.14.0",
    urls = ["https://github.com/google/googletest/archive/refs/tags/v1.14.0.tar.gz"],
)

# Stardoc dependencies.

http_archive(
    name = "io_bazel_stardoc",
    sha256 = "8b8fb2df4dcaef328e40cd833df1df263cb694999130e684b089956abd264c0b",
    strip_prefix = "stardoc-ee7f82841a96fc9a88cee42ff9d18719d51a792f",
    url = "https://github.com/bazelbuild/stardoc/archive/ee7f82841a96fc9a88cee42ff9d18719d51a792f.zip",
)

load("@io_bazel_stardoc//:setup.bzl", "stardoc_repositories")

stardoc_repositories()
