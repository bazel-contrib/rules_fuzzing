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
Validates and merges a set of fuzzing dictionary files into a single output.
"""

from absl import app
from absl import flags
from string import hexdigits

FLAGS = flags.FLAGS

flags.DEFINE_list("dict_list", [],
                  "Each element in the list stands for a dictionary file")

flags.DEFINE_string("output_file", "output.dict",
                    "The name of the output merged dictionary file")


# Validate a single entry in the dictionary
def validate_entry(entry):
    # Use set to contain hex digits to decrease the query time complexity
    hex_set = set(hexdigits)
    pos, end = 0, len(entry) - 1
    while pos < end:
        pos += 1
        chr = entry[pos]  # Single character

        if not (chr.isprintable() or chr.isspace()):
            return False

        # Handle '\\'
        if chr == '\\':
            if pos + 1 <= end and (entry[pos + 1] == '\\' or
                                   entry[pos + 1] == '"'):
                pos += 1
                continue

            # Handle '\xAB'
            if pos + 3 <= end and entry[pos + 1] == 'x' and entry[
                    pos + 2] in hex_set and entry[pos + 3] in hex_set:
                pos += 3
                continue

            return False

    return True


def validate_line(line):
    line = line.strip()
    if not line or line.startswith('#'):
        return True
    if len(line) < 2 or line[-1] != '"':
        return False

    left = 0
    # Find the opening "
    while left < len(line) - 1 and line[left] != '"':
        left += 1

    if left >= len(line) - 1:
        return False

    return validate_entry(line[left:])


def main(argv):
    with open(FLAGS.output_file, 'w') as output:
        for dic_path in FLAGS.dict_list:
            print(dic_path)
            with open(dic_path, 'r') as dic:
                for line in dic.readlines():
                    if not validate_line(line):
                        print("ERROR: invalid dictionary entry \'" +
                              line.strip() + "\'")
                        return -1
                    output.write(line)

    print("The dictionary is successfully validated.")
    return 0


if __name__ == '__main__':
    app.run(main)
