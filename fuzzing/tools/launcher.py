# Lint as: python3
"""
This is the launcher script to provide a uniform command line interface 
behind a number of arbitrary fuzzing engines.
"""

from absl import app
from absl import flags
import os

FLAGS = flags.FLAGS

flags.DEFINE_integer(
    'timeout_secs',
    20,
    'The maximum duration, in seconds, of the fuzzer run launched.',
    lower_bound=0)


def main(argv):
    if len(argv) != 2:
        raise app.UsageError(
            "This script receives 1 argument. It should look like:" +
            "\n\tpython " + __file__ + " EXECUTABLE")

    os.execv(argv[1], [
        argv[1], "-max_total_time=" + str(FLAGS.timeout_secs),
        "-timeout=" + str(FLAGS.timeout_secs)
    ])


if __name__ == '__main__':
    app.run(main)
