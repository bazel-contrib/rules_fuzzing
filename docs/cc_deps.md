<a name="#cc_fuzz_test"></a>

## cc_fuzz_test

```
cc_fuzz_test(name, corpus, **kwargs)
```

Macro for c++ fuzzing test

This macro provides below targets:
* `<name>`: an executable file built by `cc_test`.
* `<name>_run`: an executable to launch the fuzz test.
* `<name>_corpus`: a target to generate a directory containing all corpus files if the argument `corpus` is passed.
* `<name>_corpus_zip`: a target to generate a zip file containing corpus files if the argument `corpus` is passed.


**PARAMETERS**


| Name  | Description | Default Value |
| :-------------: | :-------------: | :-------------: |
| name |  A unique name for this target.   |  none |
| corpus |  A list containing corpus files, the element can be a file, a directory, or a [filegroup](https://docs.bazel.build/versions/master/be/general.html#filegroup).   |  `None` |
| kwargs |  Keyword arguments.   |  none |
