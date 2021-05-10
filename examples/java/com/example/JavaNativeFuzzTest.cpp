// Copyright 2021 Google LLC
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

#include "JavaNativeFuzzTest.h"

#include <string>

// Prevent the compiler from optimizing away the out-of-bounds read in
// parseInternal.
volatile int dummy = 0;

void parseInternal(const std::string &input) {
  if (input[0] == 'a' && input[1] == 'b' && input[5] == 'c') {
    if (input.find("secret_in_native_library") != std::string::npos) {
      // Read past null byte to trigger an OOB read.
      if (input[input.size() + 1] != 0x12)
        dummy += 1;
    }
  }
}

JNIEXPORT jboolean JNICALL Java_com_example_JavaNativeFuzzTest_parse(
    JNIEnv *env, jobject o, jstring bytes) {
  const char *input(env->GetStringUTFChars(bytes, nullptr));
  parseInternal(input);
  env->ReleaseStringUTFChars(bytes, input);
  return false;
}
