# Bazel Rules for Fuzz Tests

## Overview

This repository contains [Bazel](https://bazel.build/) [Starlark extensions](https://docs.bazel.build/versions/master/skylark/concepts.html) for defining fuzz tests in Bazel projects.

Fuzzing is an effective technique for uncovering security and stability bugs in software. Fuzzing works by invoking the code under test (e.g., a library API) with automatically generated data, and observing its execution to discover incorrect behavior, such as memory corruption or failed invariants. Covering fuzzing in detail is outside the scope of this document. Read more [here](https://github.com/google/fuzzing) about fuzzing best practices, additional examples, and other resources.

This rule library provides support for writing *in-process* fuzz tests, which consist of a driver function that receives a generated input string and feeds it to the API under test. To make a complete fuzz test executable, the driver is linked with a fuzzing engine, which implements the test generation logic. The rule library provides out-of-the-box support for the most popular fuzzing engines (e.g., [libFuzzer](https://llvm.org/docs/LibFuzzer.html) and [Honggfuzz](https://github.com/google/honggfuzz)), and an extension mechanism to define new fuzzing engines.

The goal of the fuzzing rules is to provide an easy-to-use interface for developers to specify, build, and run fuzz tests, without worrying about the details of each fuzzing engine. A fuzzing rule wraps a raw fuzz test executable and provides additional tools, such as the specification of a corpus and dictionary and a launcher that knows how to invoke the fuzzing engine with the appropriate set of flags.

The rule library currently provides support for C++ fuzz tests. Support for additional languages may be added in the future.

## Prerequisites

C++ fuzz tests require a Clang compiler. The libFuzzer engine requires at least Clang 6.0.

In addition, the Honggfuzz engine requires the `libunwind-dev` and `libblocksruntime-dev` packages.

## Getting started

The fastest way to get a sense of the fuzzing rules is through the examples provided in this repository. Assuming the current directory points to a local clone of this repository, let's explore some of the features provided by the Bazel rules.

### Defining fuzz tests

A fuzz test is specified using a [`cc_fuzz_test` rule](/docs/cc-fuzzing-rules.md#cc_fuzz_test). In the most basic form, a fuzz test requires a source file that implements the fuzz driver entry point. Let's consider a simple example that fuzzes the [RE2](https://github.com/google/re2) regular expression library:

```python
# BUILD file.

load("@rules_fuzzing//fuzzing:cc_deps.bzl", "cc_fuzz_test")

cc_fuzz_test(
    name = "re2_fuzz_test",
    srcs = ["re2_fuzz_test.cc"],
    deps = [
        "@re2",
    ],
)
```

The fuzz driver implements the special `LLVMFuzzerTestOneInput` function that receives the fuzzer-generated string and uses it to drive the API under test:

```cpp
// Implementation file.

#include <cstdint>
#include <cstddef>
#include <string>

#include "re2/re2.h"

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
    RE2 re(std::string(reinterpret_cast<const char*>(data), size), RE2::Quiet);
    return 0;
}
```

### Building and running

To build a fuzz test, you need to specify which fuzzing engine and what instrumentation to use for tracking errors during the execution of the fuzzer. Let's build the RE2 fuzz test using [libFuzzer](https://llvm.org/docs/LibFuzzer.html) and the [Address Sanitizer (ASAN)](https://clang.llvm.org/docs/AddressSanitizer.html) instrumentation, which catches memory errors such as buffer overflows and use-after-frees:

```sh
$ bazel build -c opt --config=asan-libfuzzer //examples:re2_fuzz_test
```

You can directly invoke this fuzz test executable if you know libFuzzer's command line interface. But in practice, you don't have to. For each fuzz test `<name>`, the rules library generates a number of additional targets that provide higher-level functionality to simplify the interaction with the fuzz test.

One such target is `<name>_run`, which provides a simple engine-agnostic interface for invoking fuzz tests. Let's run our libFuzzer example:

```sh
$ bazel run -c opt --config=asan-libfuzzer //examples:re2_fuzz_test_run
```

The fuzz test will start running locally, and write the generated tests under a temporary path under `/tmp/fuzzing`. By default, the generated tests persist across runs, in order to make it easy to stop and resume runs (possibly under different engines and configurations).

Let's interrupt the fuzz test execution (Ctrl-C), and resume it using the Honggfuzz engine:

```sh
$ bazel run -c opt --config=asan-honggfuzz //examples:re2_fuzz_test_run
```

The `<name>_run` target accepts a number of engine-agnostic flags. For example, the following command runs the fuzz test with an execution timeout and on a clean slate (removing any previously generated tests). Note the extra `--` separator between Bazel's own flags and the launcher flags:

```sh
$ bazel run -c opt --config=asan-libfuzzer //examples:re2_fuzz_test_run \
      -- --clean --timeout_secs=30
```

### Additional examples

Check out the [`examples/`](examples/) directory, which showcases additional features of the `cc_fuzz_test` rule.

## Using the rules in your project

To use the fuzzing rules in your project, you will need to load and set them up in your workspace, along with creating the necessary `--config` commands in your `.bazelrc` file.

### Configuring the WORKSPACE

Add the following to your `WORKSPACE` file:

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_fuzzing",
    sha256 = "a1cde2a5ccc05bdeb75bd0f4c62c6df966134a50278492468bd03ea8ffcaa133",
    strip_prefix = "rules_fuzzing-4de19aafba32cd586abf1bd66ebd3f8d2ea98350",
    urls = ["https://github.com/bazelbuild/rules_fuzzing/archive/4de19aafba32cd586abf1bd66ebd3f8d2ea98350.zip"],
)

load("@rules_fuzzing//fuzzing:repositories.bzl", "rules_fuzzing_dependencies")

rules_fuzzing_dependencies()

load("@rules_fuzzing//fuzzing:dependency_imports.bzl", "fuzzing_dependency_imports")

fuzzing_dependency_imports()
```

The project is still under active development, so you many need to change the `urls` and `sha256` attributes to get the latest features implemented at `HEAD`.

### Configuring the .bazelrc file

To make sure the fuzz tests are built with the correct instrumentation flags for each engine / instrumentation supported, we recommend using the configurations defined in this repository's [`.bazelrc` file](/.bazelrc), which you can copy and paste in your own `.bazelrc` file.

Currently, the following configurations are available, based on the fuzzing engines defined in this repository:

| Configuration             | Fuzzing engine | Instrumentation          |
|---------------------------|----------------|--------------------------|
| `--config=asan-fuzzer`    | libFuzzer      | Address Sanitizer (ASAN) |
| `--config=msan-fuzzer`    | libFuzzer      | Memory Sanitizer (MSAN)  |
| `--config=asan-honggfuzz` | Honggfuzz      | Address Sanitizer (ASAN) |

You should similarly create additional `--config` entries for any [fuzzing engines defined](#defining-fuzzing-engines) in your own repository.

## Defining fuzzing engines

> TODO: Fill in the missing documentation here.

A fuzzing engine launcher script receives configuration through the following environment variables:

| Variable                   | Description |
|----------------------------|-------------|
| `FUZZER_BINARY`            | The path to the fuzz target executable. |
| `FUZZER_TIMEOUT_SECS`      | If set, a positive integer representing the timeout in seconds for the entire fuzzer run. |
| `FUZZER_IS_REGRESSION`     | Set to `1` if the fuzzer should run in regression mode (just execute the input tests), or `0` if this is a continuous fuzzer run. |
| `FUZZER_DICTIONARY_PATH`   | If set, provides a path to a fuzzing dictionary file. |
| `FUZZER_SEED_CORPUS_DIR`   | If set, provides a directory path to a seed corpus. |
| `FUZZER_OUTPUT_ROOT`       | A writable path that can be used by the fuzzer during its execution (e.g., as a workspace or for generated artifacts). See the variables below for specific categories of output. |
| `FUZZER_OUTPUT_CORPUS_DIR` | A path under `FUZZER_OUTPUT_ROOT` where the new generated tests should be stored. |
| `FUZZER_ARTIFACTS_DIR`     | A path under `FUZZER_OUTPUT_ROOT` where generated crashes and other relevant artifacts should be stored. |

## Rule reference

* [`cc_fuzz_test`](/docs/cc-fuzzing-rules.md#cc_fuzz_test)
* [`cc_fuzzing_engine`](/docs/cc-fuzzing-rules.md#cc_fuzzing_engine)
