# Bazel Rules for Fuzz Tests

This repository contains [Bazel](https://bazel.build/) [Starlark extensions](https://docs.bazel.build/versions/master/skylark/concepts.html) for defining fuzz tests in Bazel projects.

[Fuzzing](https://en.wikipedia.org/wiki/Fuzzing) is an effective technique for uncovering security and stability bugs in software. Fuzzing works by invoking the code under test (e.g., a library API) with automatically generated data, and observing its execution to discover incorrect behavior, such as memory corruption or failed invariants. Read more [here](https://github.com/google/fuzzing) about fuzzing, additional examples, best practices, and other resources.

## Features at a glance

* Multiple fuzzing engines out of the box:
  * [libFuzzer][libfuzzer-doc]
  * [Honggfuzz][honggfuzz-doc]
* Multiple sanitizer configurations:
  * [Address Sanitizer][asan-doc]
  * [Memory Sanitizer][msan-doc]
* Corpora and dictionaries.
* Simple "bazel run/test" commands to build and run the fuzz tests.
  * No need to understand the details of each fuzzing engine.
  * No need to explicitly manage its corpus or dictionary.
* Out-of-the-box [OSS-Fuzz](https://github.com/google/oss-fuzz) support that [substantially simplifies][bazel-oss-fuzz] the project integration effort.
* Regression testing support, useful in continuous integration.
* Customization options:
  * Defining additional fuzzing engines
  * Customizing the behavior of the fuzz test rule.

The rule library currently provides support for C++ fuzz tests. Support for additional languages may be added in the future.

Contributions are welcome! Please read the [contribution guidelines](/docs/contributing.md).

## Getting started

This section will walk you through the steps to set up fuzzing in your Bazel project and write your first fuzz test. We assume Bazel [is installed](https://docs.bazel.build/versions/4.0.0/install.html) on your machine.

### Prerequisites

The fuzz tests require a Clang compiler. The libFuzzer engine requires at least Clang 6.0. In addition, the Honggfuzz engine requires the `libunwind-dev` and `libblocksruntime-dev` packages:

```sh
$ sudo apt-get install clang libunwind-dev libblocksruntime-dev
```

### Configuring the WORKSPACE

Add the following to your `WORKSPACE` file:

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_fuzzing",
    sha256 = "71fa2724c9802c597199a86111a0499fc4fb22426d322334d3f191dadeff5132",
    strip_prefix = "rules_fuzzing-0.1.0",
    urls = ["https://github.com/bazelbuild/rules_fuzzing/archive/v0.1.0.zip"],
)

load("@rules_fuzzing//fuzzing:repositories.bzl", "rules_fuzzing_dependencies")

rules_fuzzing_dependencies()

load("@rules_fuzzing//fuzzing:init.bzl", "rules_fuzzing_init")

rules_fuzzing_init()
```

> NOTE: Replace this snippet with the latest WORKSPACE setup instructions in the release notes. To get the latest unreleased features, you may need to change the `urls` and `sha256` attributes to fetch from `HEAD`.


### Configuring the .bazelrc file

It is best to create command shorthands for the fuzzing configurations you will use during development. In our case, let's create a configuration for libFuzzer + Address Sanitizer. In your `.bazelrc` file, add the following:

```
# Force the use of Clang for C++ builds.
build --action_env=CC=clang
build --action_env=CXX=clang++

# Define the --config=asan-libfuzzer configuration.
build:asan-libfuzzer --@rules_fuzzing//fuzzing:cc_engine=@rules_fuzzing//fuzzing/engines:libfuzzer
build:asan-libfuzzer --@rules_fuzzing//fuzzing:cc_engine_instrumentation=libfuzzer
build:asan-libfuzzer --@rules_fuzzing//fuzzing:cc_engine_sanitizer=asan
```

### Defining the fuzz test

A fuzz test is specified using a [`cc_fuzz_test` rule](/docs/cc-fuzzing-rules.md#cc_fuzz_test). In the most basic form, a fuzz test requires a source file that implements the fuzz driver entry point.

Let's create a fuzz test that exhibits a buffer overflow. Create a `fuzz_test.cc` file in your workspace root, as follows:

```cpp
#include <cstddef>
#include <cstdint>
#include <cstdio>

void TriggerBufferOverflow(const uint8_t *data, size_t size) {
  if (size >= 3 && data[0] == 'F' && data[1] == 'U' && data[2] == 'Z' &&
      data[size] == 'Z') {
    fprintf(stderr, "BUFFER OVERFLOW!\n");
  }
}

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  TriggerBufferOverflow(data, size);
  return 0;
}
```

Let's now define its build target in the `BUILD` file:

```python
load("@rules_fuzzing//fuzzing:cc_defs.bzl", "cc_fuzz_test")

cc_fuzz_test(
    name = "fuzz_test",
    srcs = ["fuzz_test.cc"],
)
```

### Running the fuzz test

You can now build and run the fuzz test. For each fuzz test `<name>` defined, the framework automatically generates a launcher tool `<name>_run` that will build and run the fuzz test according to the configuration specified:

```sh
$ bazel run --config=asan-libfuzzer //:fuzz_test_run
```

Our libFuzzer test will start running and immediately discover the buffer overflow issue in the code:

```
INFO: Seed: 2957541205
INFO: Loaded 1 modules   (8 inline 8-bit counters): 8 [0x5aab10, 0x5aab18), 
INFO: Loaded 1 PC tables (8 PCs): 8 [0x5aab18,0x5aab98), 
INFO:      755 files found in /tmp/fuzzing/corpus
INFO:        0 files found in fuzz_test_corpus
INFO: -max_len is not provided; libFuzzer will not generate inputs larger than 35982 bytes
INFO: seed corpus: files: 755 min: 1b max: 35982b total: 252654b rss: 35Mb
#756    INITED cov: 6 ft: 7 corp: 4/10b exec/s: 0 rss: 47Mb
=================================================================
==724294==ERROR: AddressSanitizer: heap-buffer-overflow on address 0x602000047a74 at pc 0x0000005512d9 bp 0x7fff3049d270 sp 0x7fff3049d268
```

The crash is saved under `/tmp/fuzzing/artifacts` and can be further inspected.

### OSS-Fuzz integration

Once you wrote and tested the fuzz test, you should run it on continuous fuzzing infrastructure so it starts generating tests and finding new crashes in your code.

The fuzzing rules provide out-of-the-box support for [OSS-Fuzz](https://github.com/google/oss-fuzz), free continuous fuzzing infrastructure from Google for open source projects. Read its [Bazel project guide][bazel-oss-fuzz] for detailed instructions.

## Where to go from here?

Congratulations, you have built and run your first fuzz test with the Bazel rules!

Check out the [`examples/`](examples/) directory, which showcases additional features. Read the [User Guide](/docs/guide.md) for detailed usage instructions.

<!-- Links -->

[asan-doc]: https://clang.llvm.org/docs/AddressSanitizer.html
[bazel-oss-fuzz]: https://google.github.io/oss-fuzz/getting-started/new-project-guide/bazel/
[honggfuzz-doc]: https://github.com/google/honggfuzz
[libfuzzer-doc]: https://llvm.org/docs/LibFuzzer.html
[msan-doc]: https://clang.llvm.org/docs/MemorySanitizer.html
