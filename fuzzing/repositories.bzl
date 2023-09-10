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

"""Contains the external dependencies."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_jar")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//fuzzing/private/oss_fuzz:repository.bzl", "oss_fuzz_repository")

def rules_fuzzing_dependencies(oss_fuzz = True, honggfuzz = True, jazzer = True):
    """Instantiates the dependencies of the fuzzing rules.

    Args:
      oss_fuzz: Include OSS-Fuzz dependencies.
      honggfuzz: Include Honggfuzz dependencies.
      jazzer: Include Jazzer dependencies.
    """

    maybe(
        http_archive,
        name = "platforms",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/platforms/releases/download/0.0.4/platforms-0.0.4.tar.gz",
            "https://github.com/bazelbuild/platforms/releases/download/0.0.4/platforms-0.0.4.tar.gz",
        ],
        sha256 = "079945598e4b6cc075846f7fd6a9d0857c33a7afc0de868c2ccb96405225135d",
    )
    maybe(
        http_archive,
        name = "rules_python",
        sha256 = "a644da969b6824cc87f8fe7b18101a8a6c57da5db39caa6566ec6109f37d2141",
        strip_prefix = "rules_python-0.20.0",
        url = "https://github.com/bazelbuild/rules_python/archive/refs/tags/0.20.0.tar.gz",
    )
    maybe(
        http_archive,
        name = "bazel_skylib",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
        ],
        sha256 = "1c531376ac7e5a180e0237938a2536de0c54d93f5c278634818e0efc952dd56c",
    )
    maybe(
        http_archive,
        name = "com_google_absl",
        urls = ["https://github.com/abseil/abseil-cpp/archive/f2dbd918d8d08529800eb72f23bd2829f92104a4.zip"],
        strip_prefix = "abseil-cpp-f2dbd918d8d08529800eb72f23bd2829f92104a4",
        sha256 = "5e1cbf25bf501f8e37866000a6052d02dbdd7b19a5b592251c59a4c9aa5c71ae",
    )

    if oss_fuzz:
        maybe(
            oss_fuzz_repository,
            name = "rules_fuzzing_oss_fuzz",
        )

    if honggfuzz:
        maybe(
            http_archive,
            name = "honggfuzz",
            build_file = "@rules_fuzzing//:honggfuzz.BUILD",
            sha256 = "6b18ba13bc1f36b7b950c72d80f19ea67fbadc0ac0bb297ec89ad91f2eaa423e",
            url = "https://github.com/google/honggfuzz/archive/2.5.zip",
            strip_prefix = "honggfuzz-2.5",
        )

    if jazzer:
        maybe(
            http_jar,
            name = "rules_fuzzing_jazzer",
            sha256 = "ee6feb569d88962d59cb59e8a31eb9d007c82683f3ebc64955fd5b96f277eec2",
            url = "https://repo1.maven.org/maven2/com/code-intelligence/jazzer/0.20.1/jazzer-0.20.1.jar",
        )

        maybe(
            http_jar,
            name = "rules_fuzzing_jazzer_api",
            sha256 = "f5a60242bc408f7fa20fccf10d6c5c5ea1fcb3c6f44642fec5af88373ae7aa1b",
            url = "https://repo1.maven.org/maven2/com/code-intelligence/jazzer-api/0.20.1/jazzer-api-0.20.1.jar",
        )
