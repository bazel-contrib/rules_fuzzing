# Lint as: python3
"""
This is the launcher script to provide a uniform command line interface 
behind a number of arbitrary fuzzing engines.
"""

from absl import app
from absl import flags
import os

FLAGS = flags.FLAGS

flags.DEFINE_integer('timeout', 20, 'test timeout.', lower_bound=0)


def main(argv):
    if len(argv) != 2:
        raise app.UsageError(
            "This script receives 2 arguments. It should look like:" +
            "\n\tpython " + __file__ + " EXECUTABLE --timout=TIMEOUT")

    os.execl(argv[1], argv[1], "-timeout=" + str(FLAGS.timeout))


if __name__ == '__main__':
    app.run(main)
