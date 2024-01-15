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
            "https://mirror.bazel.build/github.com/bazelbuild/platforms/releases/download/0.0.8/platforms-0.0.8.tar.gz",
            "https://github.com/bazelbuild/platforms/releases/download/0.0.8/platforms-0.0.8.tar.gz",
        ],
        sha256 = "8150406605389ececb6da07cbcb509d5637a3ab9a24bc69b1101531367d89d74",
    )
    maybe(
        http_archive,
        name = "rules_python",
        sha256 = "9d04041ac92a0985e344235f5d946f71ac543f1b1565f2cdbc9a2aaee8adf55b",
        strip_prefix = "rules_python-0.26.0",
        url = "https://github.com/bazelbuild/rules_python/releases/download/0.26.0/rules_python-0.26.0.tar.gz",
    )
    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "cd55a062e763b9349921f0f5db8c3933288dc8ba4f76dd9416aac68acee3cb94",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.5.0/bazel-skylib-1.5.0.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.5.0/bazel-skylib-1.5.0.tar.gz",
        ],
    )
    maybe(
        http_archive,
        name = "com_google_absl",
        urls = ["https://github.com/abseil/abseil-cpp/archive/refs/tags/20230802.1.zip"],
        strip_prefix = "abseil-cpp-20230802.1",
        sha256 = "497ebdc3a4885d9209b9bd416e8c3f71e7a1fb8af249f6c2a80b7cbeefcd7e21",
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
