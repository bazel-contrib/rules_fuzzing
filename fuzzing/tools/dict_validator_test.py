#
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

# Lint as: python3
"""
Tests for dict_validator.py
"""

from bazel_tools.tools.python.runfiles import runfiles
from dict_validator import validate_line
import sys

if __name__ == '__main__':
    rf = runfiles.Create()
    with open(rf.Rlocation("__main__/fuzzing/tools/dict_data/valid.dict"),
              'r') as dic:
        for line in dic.readlines():
            if not validate_line(line):
                print("ERROR: valid dictionary entry '" + line.strip() +
                      "' can't pass the check")
                sys.exit(-1)

    with open(rf.Rlocation("__main__/fuzzing/tools/dict_data/invalid.dict"),
              'r') as dic:
        for line in dic.readlines():
            if validate_line(line):
                print("ERROR: invalid dictionary entry '" + line.strip() +
                      "' can pass the check")
                sys.exit(-1)
