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
This script is used to validate the format of the fuzzing dictionary
"""

from absl import app
from absl import flags
from string import hexdigits

FLAGS = flags.FLAGS


# Validate a single entry in the dictionary
def validate_entry(line):
    line = line.strip()
    if not line or line.startswith('#'):
        return True
    if len(line) < 2 or line[-1] != '"':
        return False

    left, right = 0, len(line) - 1
    # Find the opening "
    while left < right and line[left] != '"':
        left += 1

    if left >= right:
        return False

    # Use set to contain hex digits to decrease the query time complexity
    hex_set = set(hexdigits)
    while left < right:
        left += 1
        chr = line[left]  # Single character

        if not (chr.isprintable() or chr.isspace()):
            return False

        # Handle '\\'
        if chr == '\\':
            if left + 1 <= right and (line[left + 1] == '\\' or
                                      line[left + 1] == '"'):
                left += 1
                continue

            # Handle '\xAB'
            if left + 3 <= right and line[left + 1] == 'x' and line[
                    left + 2] in hex_set and line[left + 3] in hex_set:
                left += 3
                continue

            return False

    return True


def main(argv):
    if len(argv) != 2:
        raise app.UsageError(
            "This script receives 1 argument. It should look like:" +
            "\n\tpython " + __file__ + " DICTIONARY)+_FILE")
    dic_path = argv[1]
    with open(dic_path, "r") as dic:
        for line in dic.readlines():
            if not validate_entry(line):
                print("ERROR: invalid dictionary entry \'" + line.strip() +
                      "\'")
                return -1

    print("The dictionary is successfully validated")
    return 0


if __name__ == '__main__':
    app.run(main)
