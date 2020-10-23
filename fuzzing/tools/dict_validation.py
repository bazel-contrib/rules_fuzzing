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
Validates the fuzzing dictionary.
"""

from string import hexdigits


def validate_entry(entry):
    """Validates a single fuzzing dictionary entry.

    Args:
        entry: a string containing a single entry.

    Returns:
        True if the argument is a valid fuzzing dictionary entry, 
        otherwise False.
    """

    # Use set to contain hex digits to decrease the query time complexity
    hex_set = set(hexdigits)
    pos, end = 0, len(entry) - 1
    while pos < end:
        pos += 1
        chr = entry[pos]

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
    """Validates a single line in the fuzzing dictionary entry.

    Args:
        line: a string containing a single line in the fuzzing dictionary.

    Returns:
        True if the argument is allowed to exist in a fuzzing dictionary, 
        otherwise False.
    """
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
