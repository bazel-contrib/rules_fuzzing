// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "fuzzing/replay/status_util.h"

#include <cstring>
#include <string>

#include "absl/status/status.h"
#include "absl/strings/str_cat.h"

namespace fuzzing {

namespace {

constexpr size_t kMaxErrorStringSize = 128;

std::string StrError(int errno_value) {
  char error_str_buf[kMaxErrorStringSize];
#if (_POSIX_C_SOURCE >= 200112L) && !_GNU_SOURCE
  const int result =
      strerror_r(errno_value, error_str_buf, sizeof(error_str_buf));
  if (result) {
    return absl::StrCat("Unknown error ", errno_value);
  } else {
    return error_str_buf;
  }
#else
  return strerror_r(errno_value, error_str_buf, sizeof(error_str_buf));
#endif
}

}  // namespace

absl::Status ErrnoStatus(absl::string_view message, int errno_value) {
  if (errno_value == 0) {
    return absl::OkStatus();
  } else {
    return absl::UnknownError(
        absl::StrCat(message, " (", StrError(errno_value), ")"));
  }
}

}  // namespace fuzzing
