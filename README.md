# Bazel Rules for Fuzz Tests

This repository contains [Bazel](https://bazel.build/)
[Starlark extensions](https://docs.bazel.build/versions/master/skylark/concepts.html)
for defining fuzz tests in Bazel projects. 

**This is not an officially supported Google product.**

## Requirements

To use the Bazel rules for fuzzing, your C++ toolchain should be Clang-based and configured to build the fuzz tests under several compiler instrumentation modes.

The most convenient way to set up your toolchain is by editing the [`.bazelrc` file](https://docs.bazel.build/versions/master/guide.html#bazelrc-the-bazel-configuration-file) of your project and grouping the build configuration options into `--config` groups. We recommend using [this setup](/.bazelrc), which you can copy and paste in your own `.bazelrc` file. The setup defines the following build modes:

- `--config=asan-libfuzzer` builds the fuzz target in [libFuzzer](https://llvm.org/docs/LibFuzzer.html) mode, with [Address Sanitizer (ASAN)](https://clang.llvm.org/docs/AddressSanitizer.html) instrumentation.
- `--config=msan-libfuzzer` builds the fuzz target in libFuzzer mode, with [Memory Sanitizer (MSAN)](https://clang.llvm.org/docs/MemorySanitizer.html) instrumentation.
- `--config=asan-honggfuzz` builds the fuzz target using [Honggfuzz](https://github.com/google/honggfuzz), with ASAN instrumentation.

The rest of the documentation assumes the build configuration options are accessible through these names.

## Getting started

To import the fuzzing rules in your project, you first need to add the snippet below to your `WORKSPACE` file:

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
        name = "rules_fuzzing",
        sha256 = "8901c2438fb94b55b160e82dd14a8fc3c208f948497822946319c60939c34c4f",
        strip_prefix = "bazel-rules-fuzzing-bc4b3afc59a56cec8c61f964efa93fa81e3eb6a8",
        urls = ["https://github.com/googleinterns/bazel-rules-fuzzing/archive/bc4b3afc59a56cec8c61f964efa93fa81e3eb6a8.zip"],
)
load("@rules_fuzzing//fuzzing:repositories.bzl", "rules_fuzzing_dependencies")
rules_fuzzing_dependencies()

load("@rules_fuzzing//fuzzing:dependency_imports.bzl", "fuzzing_dependency_imports")
fuzzing_dependency_imports()

load("@fuzzing_py_deps//:requirements.bzl", fuzzing_py_install = "pip_install")
fuzzing_py_install()
```

Our project is under active development, to use the latest feature, 
change the `urls` and `sha256` value above to the latest commit.

## Rule reference

* [cc fuzzing rules](fuzzing/cc_deps.bzl)
* [common rules](fuzzing/common.bzl)

## Examples

Tiny example:

Assume that you have a `fuzz_test.cc` file to do the fuzzing test and corpus files `corpus_1.txt` and `corpus_dir/*`.

You can create a fuzz test target in the `BUILD` like below:

```python
load("@rules_fuzzing//fuzzing:cc_deps.bzl", "cc_fuzz_test")

cc_fuzz_test(
    name = "fuzz_test",
    srcs = ["fuzz_test.cc"],
    corpus = ["corpus_1.txt"] + glob(["corpus_dir/**"],
)
```

To run the fuzz target, use the following command:

```sh
$ bazel run fuzz_test_run --config=asan-libfuzzer
```

You can also control the fuzzing test running time by passing `--timeout_secs` like

```sh
$ bazel run fuzz_test_run --config=asan-libfuzzer -- --timeout_secs=20
```

If you only want to run the regression test on the corpus, set `--regression`:

```sh
$ bazel run fuzz_test_run --config=asan-libfuzzer -- --regression=True
```

See the [examples](https://github.com/googleinterns/bazel-rules-fuzzing/tree/master/examples)
directory for more examples.

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
