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
Unit tests for dict_validator.py
"""

import unittest

from dict_validator import validate_line


class DictValidatorTest(unittest.TestCase):

    def test_valid_line(self):
        valid_lines = """# valid dictionary entries
":path"
"keep-alive"
"te"
# Lines starting with '#' and empty lines are ignored.

# Adds "blah" (w/o quotes) to the dictionary.
kw1="blah"
# Use \\\\ for backslash and \\" for quotes.
kw2="\\"ac\\\\dc\\""
# Use \\xAB for hex values
kw3="\\xF7\\xF8""
# the name of the keyword followed by '=' may be omitted:
"foo\\x0Abar"
"ab""
"""
        for line in valid_lines.split('\n'):
            # if not validate_line(line):
            # print(line)
            self.assertTrue(validate_line(line))

    def test_invalid_line(self):
        invalid_lines = """ Invalid dictionary entries
"
"\\A" """
        for line in invalid_lines.split('\n'):
            self.assertFalse(validate_line(line))


if __name__ == '__main__':
    unittest.main()
