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
        sha256 = "8d98c444600ce25082b320a3364150806109fe33620a4e1c5bb856861591acb9",
        urls = ["https://github.com/googleinterns/bazel-rules-fuzzing/archive/8520424714e827ff0360283e3237e35c8723d931.zip"],
load("@rules_fuzzing//fuzzing:repositories.bzl", "rules_fuzzing_dependencies")
rules_fuzzing_dependencies()
```

## Rule reference

* [cc fuzzing rules](docs/cc_deps.md)
* [common rules](docs/common.md)

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

If your `.bazelrc` has config `libfuzzer`:

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
