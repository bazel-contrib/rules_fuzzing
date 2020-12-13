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
cc_fuzz_test(<a href="#cc_fuzz_test-name">name</a>, <a href="#cc_fuzz_test-corpus">corpus</a>, <a href="#cc_fuzz_test-dicts">dicts</a>, <a href="#cc_fuzz_test-engine">engine</a>, <a href="#cc_fuzz_test-tags">tags</a>, <a href="#cc_fuzz_test-binary_kwargs">binary_kwargs</a>)
</pre>

Defines a fuzz test and a few associated tools and metadata.

For each fuzz test `<name>`, this macro expands into a number of targets:

* `<name>`: The instrumented fuzz test executable. Use this target for
  debugging or for accessing the complete command line interface of the
  fuzzing engine. Most developers should only need to use this target
  rarely.
* `<name>_run`: An executable target used to launch the fuzz test using a
  simpler, engine-agnostic command line interface.
* `<name>_corpus`: Generates a corpus directory containing all the corpus
  files specified in the `corpus` attribute.
* `<name>_dict`: Validates the set of dictionary files provided and emits
  the result to a `<name>.dict` file.
* `<name>_raw`: The raw, uninstrumented fuzz test executable. This should be
  rarely needed and may be useful when debugging instrumentation-related
  build failures or misbehavior.

> TODO: Document here the command line interface of the `<name>_run`
targets.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="cc_fuzz_test-name"></a>name |  A unique name for this target. Required.   |  none |
| <a id="cc_fuzz_test-corpus"></a>corpus |  A list containing corpus files.   |  <code>None</code> |
| <a id="cc_fuzz_test-dicts"></a>dicts |  A list containing dictionaries.   |  <code>None</code> |
| <a id="cc_fuzz_test-engine"></a>engine |  A label pointing to the fuzzing engine to use.   |  <code>"@rules_fuzzing//fuzzing:cc_engine"</code> |
| <a id="cc_fuzz_test-tags"></a>tags |  Tags set on the fuzz test executable.   |  <code>None</code> |
| <a id="cc_fuzz_test-binary_kwargs"></a>binary_kwargs |  Keyword arguments directly forwarded to the fuzz test   binary rule.   |  none |


