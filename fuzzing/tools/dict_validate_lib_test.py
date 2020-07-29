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
from dict_validate_lib import validate_line


class DictValidatorTest(unittest.TestCase):

    def test_plain_entries(self):
        lines = """kw1="blah"
":path"
"keep-alive"
"ab""
"te" """
        for line in lines.split('\n'):
            self.assertTrue(validate_line(line))

    def test_escaped_words(self):
        line = 'kw2="\\"ac\\\\dc\\""'
        self.assertTrue(validate_line(line))

    def test_hex_escapes(self):
        lines = """kw3="\\xF7\\xF8""
"foo\\x0Abar" """
        for line in lines.split('\n'):
            self.assertTrue(validate_line(line))
        invalid_hex_str = '"\\A"'
        self.assertFalse(validate_line(invalid_hex_str))

    def test_comment(self):
        line = """# valid dictionary entries"""
        self.assertTrue(validate_line(line))

    def test_empty_string(self):
        line = ""
        self.assertTrue(validate_line(line))

    def test_spaces(self):
        line = "   "
        self.assertTrue(validate_line(line))

    def test_plain_words(self):
        line = "Invalid dictionary entries"
        self.assertFalse(validate_line(line))

    def test_single_quote(self):
        line = '"'
        self.assertFalse(validate_line(line))


if __name__ == '__main__':
    unittest.main()
