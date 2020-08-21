# Bazel Rules for Fuzz Tests

This repository contains [Bazel](https://bazel.build/)
[Starlark extensions](https://docs.bazel.build/versions/master/skylark/concepts.html)
for defining fuzz tests in Bazel projects. 

**This is not an officially supported Google product.**

## Getting started

To import the fuzzing rules in your project, you first need to add the snippet below to your `WORKSPACE` file:

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
        name = "rules_fuzzing",
        sha256 = "3bf7f43c095bc1aa0b6bde9d110b5b7c2e1ecb5c65919b01d19c591172230fd9",
        strip_prefix = "bazel-rules-fuzzing-9ae0b0a1f4cca0ea2e26e9f7da0754904488398a",
        urls = ["https://github.com/googleinterns/bazel-rules-fuzzing/archive/9ae0b0a1f4cca0ea2e26e9f7da0754904488398a.zip"],
)
load("@rules_fuzzing//fuzzing:repositories.bzl", "rules_fuzzing_dependencies")
rules_fuzzing_dependencies()

load("@rules_fuzzing//fuzzing:dependency_imports.bzl", "fuzzing_dependency_imports")
fuzzing_dependency_imports()

load("@fuzzing_py_deps//:requirements.bzl", fuzzing_py_install = "pip_install")
fuzzing_py_install()
```

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

If your `.bazelrc` in the project root directory has config `libfuzzer`:

```
build:libfuzzer --action_env=CC=clang
build:libfuzzer --action_env=CXX=clang++
build:libfuzzer --linkopt=-fsanitize=fuzzer
build:libfuzzer --copt=-fsanitize=fuzzer
```

you then can run the fuzz test above using command

```python
bazel run fuzz_test_run --config=libfuzzer
```

You can also control the fuzzing test running time by passing `--timeout_secs` like

```python
bazel run fuzz_test_run --config=libfuzzer -- --timeout_secs=20
```

Feel free to copy the config setting in [.bazelrc](https://github.com/googleinterns/bazel-rules-fuzzing/blob/master/.bazelrc) to yours.


See the [examples](https://github.com/googleinterns/bazel-rules-fuzzing/tree/master/examples)
directory for more examples.
