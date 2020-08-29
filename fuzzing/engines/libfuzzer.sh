#!/bin/sh

exec ${FUZZING_BINARY} \
  "${FUZZING_SEED_CORPUS}" \
  -dict="${FUZZING_DICT_PATH}" \
  -timeout="${FUZZING_TIMEOUT_SEC}" \
  "$@"  \