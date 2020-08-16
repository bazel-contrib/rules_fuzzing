<a name="#fuzzing_launcher"></a>

## fuzzing_launcher

```
fuzzing_launcher(name, corpus, is_regression, target)
```


This rule creates a script to start the fuzzing test.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| name |  A unique name for this target.   | [Name](https://bazel.build/docs/build-ref.html#name) | required |  |
| corpus |  The target to create a directory containing corpus files.   | [Label](https://bazel.build/docs/build-ref.html#labels) | optional | None |
| is_regression |  If set true the target is for a regression test.   | Boolean | optional | True |
| target |  The fuzzing test to run.   | [Label](https://bazel.build/docs/build-ref.html#labels) | required |  |


<a name="#fuzzing_corpus"></a>

## fuzzing_corpus

```
fuzzing_corpus(name, srcs)
```


This rule generates a `<name>_corpus` directory collecting all the corpus files 
specified in the `srcs` attribute.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| name |  A unique name for this target.   | [Name](https://bazel.build/docs/build-ref.html#name) | required |  |
| srcs |  The corpus files for the fuzzing test.   | [List of labels](https://bazel.build/docs/build-ref.html#labels) | optional | [] |


<a name="#fuzzing_dictionary"></a>

## fuzzing_dictionary

```
fuzzing_dictionary(name, dicts, output)
```


This rule validates the fuzzing dictionaries and output a merged dictionary.

If an invalid dictionary entry is found, the validation process will terminate with an error message "ERROR: invalid dictionary entry INVALID_ENTRY".

Check [libfuzzer dictionaries](https://llvm.org/docs/LibFuzzer.html#id31) for more information about the valid dictionary entries.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| name |  A unique name for this target.   | [Name](https://bazel.build/docs/build-ref.html#name) | required |  |
| dicts |  The fuzzing dictionaries.   | [List of labels](https://bazel.build/docs/build-ref.html#labels) | required |  |
| output |  The name of the merged dictionary.   | String | required |  |
