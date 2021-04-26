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

load("//fuzzing:cc_defs.bzl", "cc_fuzzing_engine")
load("//fuzzing:java_defs.bzl", "java_fuzzing_engine")
load("@rules_cc//cc:defs.bzl", "cc_library")

# libFuzzer specification.
##########################

cc_fuzzing_engine(
    name = "libfuzzer",
    display_name = "libFuzzer",
    launcher = "libfuzzer_launcher.sh",
    library = ":libfuzzer_stub",
    visibility = ["//visibility:public"],
)

cc_library(
    name = "libfuzzer_stub",
    srcs = ["libfuzzer_stub.cc"],
    linkopts = [
        # We add the linker options to the library, so only the fuzz test binary
        # is linked with libfuzzer.
        "-fsanitize=fuzzer",
    ],
)

# Honggfuzz specification.
##########################

cc_fuzzing_engine(
    name = "honggfuzz",
    display_name = "Honggfuzz",
    launcher = "honggfuzz_launcher.sh",
    launcher_data = {
        "@honggfuzz//:honggfuzz": "HONGGFUZZ_PATH",
    },
    library = "@honggfuzz//:honggfuzz_engine",
    visibility = ["//visibility:public"],
)

# The replay engine specification.
##################################

cc_fuzzing_engine(
    name = "replay",
    display_name = "Replay",
    launcher = "replay_launcher.sh",
    library = "//fuzzing/replay:replay_main",
    visibility = ["//visibility:public"],
)

# Jazzer specification.
#################################

java_fuzzing_engine(
    name = "jazzer",
    display_name = "Jazzer",
    launcher = "jazzer_launcher.sh",
    library = "@jazzer//agent:jazzer_api_compile_only",
    visibility = ["//visibility:public"],
)
