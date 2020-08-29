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

load("@rules_fuzzing//fuzzing:common.bzl", "cc_fuzzing_engine")

cc_fuzzing_engine(
    name = "libfuzzer",
    display_name = "LibFuzzer",
    # main_library = ":libfuzzer_main",
    launcher_script = "libfuzzer.sh",
)

# Defines the entry point for libFuzzer executables.
# cc_library(
#     name = "libfuzzer_main",
#     deps = [...],
# )
