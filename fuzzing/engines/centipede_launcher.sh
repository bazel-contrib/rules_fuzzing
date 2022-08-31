# Copyright 2022 Google LLC
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

command_line="$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' ${CENTIPEDE_PATH})"
# command_line+=("--alsologtostderr")
command_line+=("--workdir=${FUZZER_OUTPUT_ROOT}")
command_line+=("--symbolizer_path=${LLVM_SYMBOLIZER_PATH}")

if [[ -n "${FUZZER_SEED_CORPUS_DIR}" ]]; then
    >&2 echo "WARNING: Seed corpus not supported yet."
fi
if (( FUZZER_IS_REGRESSION )); then
    >&2 echo "ERROR: Regression mode not supported yet."
    exit 1
fi

command_line+=("--binary=${FUZZER_BINARY}")

echo "${command_line[@]}"
exec "${command_line[@]}" "$@"
