<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a id="#cc_fuzzing_engine"></a>

## cc_fuzzing_engine

<pre>
cc_fuzzing_engine(<a href="#cc_fuzzing_engine-name">name</a>, <a href="#cc_fuzzing_engine-data">data</a>, <a href="#cc_fuzzing_engine-display_name">display_name</a>, <a href="#cc_fuzzing_engine-launcher">launcher</a>, <a href="#cc_fuzzing_engine-library">library</a>)
</pre>


Specifies a fuzzing engine that can be used to run C++ fuzz targets.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cc_fuzzing_engine-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="cc_fuzzing_engine-data"></a>data |  A dict mapping additional runtime dependencies needed by the fuzzing engine to environment variables that will be available inside the launcher, holding the runtime path to the dependency.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: Label -> String</a> | optional | {} |
| <a id="cc_fuzzing_engine-display_name"></a>display_name |  The name of the fuzzing engine, as it should be rendered in human-readable output.   | String | required |  |
| <a id="cc_fuzzing_engine-launcher"></a>launcher |  A shell script that knows how to launch the fuzzing executable based on configuration specified in the environment.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="cc_fuzzing_engine-library"></a>library |  A cc_library target that implements the fuzzing engine entry point.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |


<a id="#cc_fuzz_test"></a>

## cc_fuzz_test

<pre>
cc_fuzz_test(<a href="#cc_fuzz_test-name">name</a>, <a href="#cc_fuzz_test-corpus">corpus</a>, <a href="#cc_fuzz_test-dicts">dicts</a>, <a href="#cc_fuzz_test-binary_kwargs">binary_kwargs</a>)
</pre>

Macro for c++ fuzzing test

This macro provides below targets:
<name>: the executable file built by cc_test.
<name>_run: an executable to launch the fuzz test.
<name>_corpus: a target to generate a directory containing all corpus files if the argument corpus is passed.
<name>_corpus_zip: an target to generate a zip file containing corpus files if the argument corpus is passed.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="cc_fuzz_test-name"></a>name |  A unique name for this target. Required.   |  none |
| <a id="cc_fuzz_test-corpus"></a>corpus |  A list containing corpus files.   |  <code>None</code> |
| <a id="cc_fuzz_test-dicts"></a>dicts |  A list containing dictionaries.   |  <code>None</code> |
| <a id="cc_fuzz_test-binary_kwargs"></a>binary_kwargs |  Keyword arguments directly forwarded to the fuzz test binary rule.   |  none |


