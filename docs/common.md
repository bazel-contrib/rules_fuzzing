<a name="#fuzzing_launcher"></a>

## fuzzing_launcher

<pre>
fuzzing_launcher(<a href="#fuzzing_launcher-name">name</a>, <a href="#fuzzing_launcher-corpus">corpus</a>, <a href="#fuzzing_launcher-is_regression">is_regression</a>, <a href="#fuzzing_launcher-target">target</a>)
</pre>


This rule creates a script to start the fuzzing test.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| corpus |  The target to create a directory containing corpus files.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| is_regression |  If set true the target is for a regression test.   | Boolean | optional | True |
| target |  The fuzzing test to run.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |


<a name="#fuzzing_corpus"></a>

## fuzzing_corpus

<pre>
fuzzing_corpus(<a href="#fuzzing_corpus-name">name</a>, <a href="#fuzzing_corpus-srcs">srcs</a>)
</pre>


This rule generates a `<name>_corpus` directory collecting all the corpus files 
specified in the `srcs` attribute.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| srcs |  The corpus files for the fuzzing test.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |


<a name="#fuzzing_dictionary"></a>

## fuzzing_dictionary

<pre>
fuzzing_dictionary(<a href="#fuzzing_dictionary-name">name</a>, <a href="#fuzzing_dictionary-dicts">dicts</a>, <a href="#fuzzing_dictionary-output">output</a>)
</pre>


This rule validates the fuzzing dictionaries and output a merged dictionary.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| dicts |  The fuzzing dictionaries.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | required |  |
| output |  The name of the merged dictionary.   | String | required |  |
