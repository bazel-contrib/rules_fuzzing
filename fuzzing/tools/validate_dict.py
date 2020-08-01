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
from dict_validation import validate_line
from sys import stderr

FLAGS = flags.FLAGS

flags.DEFINE_list("dict_list", [],
                  "Each element in the list stands for a dictionary file")

flags.DEFINE_string("output_file", "",
                    "The name of the output merged dictionary file")


def validate_dic(dic_path, output_stream):
    with open(dic_path, 'r') as dic:
        for line in dic.readlines():
            if not validate_line(line):
                print("ERROR: invalid dictionary entry \'" + line.strip() +
                      "\'",
                      file=stderr)
                return False
            if output_stream:
                output_stream.write(line)
    return True


def main(argv):
    output = open(FLAGS.output_file, 'w') if FLAGS.output_file else None
    try:
        for dic_path in FLAGS.dict_list:
            if not validate_dic(dic_path, output):
                return -1
    finally:
        if output:
            output.close()
    return 0


if __name__ == '__main__':
    app.run(main)