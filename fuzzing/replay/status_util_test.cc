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

#include <cerrno>

#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace fuzzing {

namespace {

using ::testing::StrEq;

TEST(StatusUtilTest, EmptyMessage) {
  const absl::Status status = ErrnoStatus("", ENOENT);
  EXPECT_EQ(status.code(), absl::StatusCode::kUnknown);
  EXPECT_THAT(status.message(), StrEq(" (No such file or directory)"));
}

TEST(StatusUtilTest, NonemptyMessage) {
  const absl::Status status = ErrnoStatus("could not open file", ENOENT);
  EXPECT_EQ(status.code(), absl::StatusCode::kUnknown);
  EXPECT_THAT(status.message(),
              StrEq("could not open file (No such file or directory)"));
}

TEST(StatusUtilTest, SuccessfulErrno) {
  const absl::Status status = ErrnoStatus("no error", 0);
  EXPECT_EQ(status.code(), absl::StatusCode::kUnknown);
  EXPECT_THAT(status.message(), StrEq("no error (Success)"));
}

TEST(StatusUtilTest, UnknownErrno) {
  const absl::Status status = ErrnoStatus("some error", 123456);
  EXPECT_EQ(status.code(), absl::StatusCode::kUnknown);
  EXPECT_THAT(status.message(), StrEq("some error (Unknown error 123456)"));
}

}  // namespace

}  // namespace fuzzing
