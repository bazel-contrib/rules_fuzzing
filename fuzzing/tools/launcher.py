# Lint as: python3
"""
This is the launcher script to provide a uniform command line interface behind a number of arbitrary fuzzing engines.
"""

from absl import app
from absl import flags
from subprocess import call, TimeoutExpired
import os

FLAGS = flags.FLAGS

flags.DEFINE_integer('timeout', 20, 'test timeout.', lower_bound=0)
flags.DEFINE_enum('engine', 'libfuzzer', ['libfuzzer'],
                  'the fuzzing engine used to do fuzzing test.')


def main(argv):
    if len(argv) < 2:
        raise app.UsageError("Too few arguments")

    ret_code = 0
    cwd = os.getcwd()
    try:
        # Is this the right way to execute the runnable?
        ret_code = call(cwd + "/../../../" + argv[1], timeout=FLAGS.timeout)
    except TimeoutExpired as e:
        print("Error: Timeout")
    except Exception as e:
        print("Error: " + str(e))
    if ret_code:
        print("Error: " + str(ret_code))


if __name__ == '__main__':
    app.run(main)
