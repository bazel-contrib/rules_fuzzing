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
Copies and renames a set of corpus files into a given directory.
"""

from absl import app
from absl import flags
from sys import stderr
import glob
import os
import shutil

FLAGS = flags.FLAGS

flags.DEFINE_list("corpus_list", [],
                  "Each element in the list stands for a corpus file")

flags.DEFINE_string("output_dir", None, "The path of the output directory")

flags.mark_flag_as_required("output_dir")


def main(argv):
    if not os.path.exists(FLAGS.output_dir):
        os.makedirs(FLAGS.output_dir)

    expanded_file_list = []
    for corpus in FLAGS.corpus_list:
        if not os.path.exists(corpus):
            print("ERROR: file " + corpus + " doesn't exist.", file=stderr)
            return -1
        if os.path.isdir(corpus):
            # The first element in glob("dir/**") is "dir/", which needs to be excluded
            expanded_file_list += glob.glob(os.path.join(corpus, "**"), recursive=True)[1:]
        else:
            expanded_file_list.append(corpus)
    
    if expanded_file_list:
        for corpus in expanded_file_list:
            dest = os.path.join(FLAGS.output_dir, corpus.replace("/", "-"))
            # Whatever the separator we choose, there is an chance that
            # the dest name conflicts with another file
            if os.path.exists(dest):
                print("ERROR: file " + dest + " existed.", file=stderr)
                return -1
            shutil.copy(corpus, dest)
    else:
        open(os.path.join(FLAGS.output_dir, "empty_test"), "a").close()
    return 0


if __name__ == '__main__':
    app.run(main)
