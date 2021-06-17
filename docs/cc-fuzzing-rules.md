<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a id="#cc_fuzzing_engine"></a>

## cc_fuzzing_engine

<pre>
cc_fuzzing_engine(<a href="#cc_fuzzing_engine-name">name</a>, <a href="#cc_fuzzing_engine-display_name">display_name</a>, <a href="#cc_fuzzing_engine-launcher">launcher</a>, <a href="#cc_fuzzing_engine-launcher_data">launcher_data</a>, <a href="#cc_fuzzing_engine-library">library</a>)
</pre>


Specifies a fuzzing engine that can be used to run C++ fuzz targets.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cc_fuzzing_engine-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="cc_fuzzing_engine-display_name"></a>display_name |  The name of the fuzzing engine, as it should be rendered in human-readable output.   | String | required |  |
| <a id="cc_fuzzing_engine-launcher"></a>launcher |  A shell script that knows how to launch the fuzzing executable based on configuration specified in the environment.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="cc_fuzzing_engine-launcher_data"></a>launcher_data |  A dict mapping additional runtime dependencies needed by the fuzzing engine to environment variables that will be available inside the launcher, holding the runtime path to the dependency.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: Label -> String</a> | optional | {} |
| <a id="cc_fuzzing_engine-library"></a>library |  A cc_library target that implements the fuzzing engine entry point.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |


<a id="#FuzzingEngineInfo"></a>

## FuzzingEngineInfo

<pre>
FuzzingEngineInfo(<a href="#FuzzingEngineInfo-display_name">display_name</a>, <a href="#FuzzingEngineInfo-launcher">launcher</a>, <a href="#FuzzingEngineInfo-launcher_runfiles">launcher_runfiles</a>, <a href="#FuzzingEngineInfo-launcher_environment">launcher_environment</a>)
</pre>


Provider for storing the language-independent part of the specification of a fuzzing engine.


**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="FuzzingEngineInfo-display_name"></a>display_name |  A string representing the human-readable name of the fuzzing engine.    |
| <a id="FuzzingEngineInfo-launcher"></a>launcher |  A file representing the shell script that launches the fuzz target.    |
| <a id="FuzzingEngineInfo-launcher_runfiles"></a>launcher_runfiles |  The runfiles needed by the launcher script on the fuzzing engine side, such as helper tools and their data dependencies.    |
| <a id="FuzzingEngineInfo-launcher_environment"></a>launcher_environment |  A dictionary from environment variables to files used by the launcher script.    |


<a id="#cc_fuzz_test"></a>

## cc_fuzz_test

<pre>
cc_fuzz_test(<a href="#cc_fuzz_test-name">name</a>, <a href="#cc_fuzz_test-corpus">corpus</a>, <a href="#cc_fuzz_test-dicts">dicts</a>, <a href="#cc_fuzz_test-engine">engine</a>, <a href="#cc_fuzz_test-tags">tags</a>, <a href="#cc_fuzz_test-binary_kwargs">binary_kwargs</a>)
</pre>

Defines a C++ fuzz test and a few associated tools and metadata.

For each fuzz test `<name>`, this macro defines a number of targets. The
most relevant ones are:

* `<name>`: A test that executes the fuzzer binary against the seed corpus
  (or on an empty input if no corpus is specified).
* `<name>_bin`: The instrumented fuzz test executable. Use this target
  for debugging or for accessing the complete command line interface of the
  fuzzing engine. Most developers should only need to use this target
  rarely.
* `<name>_run`: An executable target used to launch the fuzz test using a
  simpler, engine-agnostic command line interface.
* `<name>_oss_fuzz`: Generates a `<name>_oss_fuzz.tar` archive containing
  the fuzz target executable and its associated resources (corpus,
  dictionary, etc.) in a format suitable for unpacking in the $OUT/
  directory of an OSS-Fuzz build. This target can be used inside the
  `build.sh` script of an OSS-Fuzz project.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="cc_fuzz_test-name"></a>name |  A unique name for this target. Required.   |  none |
| <a id="cc_fuzz_test-corpus"></a>corpus |  A list containing corpus files.   |  <code>None</code> |
| <a id="cc_fuzz_test-dicts"></a>dicts |  A list containing dictionaries.   |  <code>None</code> |
| <a id="cc_fuzz_test-engine"></a>engine |  A label pointing to the fuzzing engine to use.   |  <code>"@rules_fuzzing//fuzzing:cc_engine"</code> |
| <a id="cc_fuzz_test-tags"></a>tags |  Tags set on the fuzzing regression test.   |  <code>None</code> |
| <a id="cc_fuzz_test-binary_kwargs"></a>binary_kwargs |  Keyword arguments directly forwarded to the fuzz test   binary rule.   |  none |


<a id="#fuzzing_decoration"></a>

## fuzzing_decoration

<pre>
fuzzing_decoration(<a href="#fuzzing_decoration-name">name</a>, <a href="#fuzzing_decoration-raw_binary">raw_binary</a>, <a href="#fuzzing_decoration-engine">engine</a>, <a href="#fuzzing_decoration-corpus">corpus</a>, <a href="#fuzzing_decoration-dicts">dicts</a>, <a href="#fuzzing_decoration-instrument_binary">instrument_binary</a>,
                   <a href="#fuzzing_decoration-define_regression_test">define_regression_test</a>, <a href="#fuzzing_decoration-test_tags">test_tags</a>)
</pre>

Generates the standard targets associated to a fuzz test.

This macro can be used to define custom fuzz test rules in case the default
`cc_fuzz_test` macro is not adequate. Refer to the `cc_fuzz_test` macro
documentation for the set of targets generated.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="fuzzing_decoration-name"></a>name |  The name prefix of the generated targets. It is normally the   fuzz test name in the BUILD file.   |  none |
| <a id="fuzzing_decoration-raw_binary"></a>raw_binary |  The label of the cc_binary or cc_test of fuzz test   executable.   |  none |
| <a id="fuzzing_decoration-engine"></a>engine |  The label of the fuzzing engine used to build the binary.   |  none |
| <a id="fuzzing_decoration-corpus"></a>corpus |  A list of corpus files.   |  <code>None</code> |
| <a id="fuzzing_decoration-dicts"></a>dicts |  A list of fuzzing dictionary files.   |  <code>None</code> |
| <a id="fuzzing_decoration-instrument_binary"></a>instrument_binary |  **(Experimental, may be removed in the future.)**<br><br>  By default, the generated targets depend on <code>raw_binary</code> through   a Bazel configuration using flags from the <code>@rules_fuzzing//fuzzing</code>   package to determine the fuzzing build mode, engine, and sanitizer   instrumentation.<br><br>  When this argument is false, the targets assume that <code>raw_binary</code> is   already built in the proper configuration and will not apply the   transition.<br><br>  Most users should not need to change this argument. If you think the   default instrumentation mode does not work for your use case, please   file a Github issue to discuss.   |  <code>True</code> |
| <a id="fuzzing_decoration-define_regression_test"></a>define_regression_test |  If true, generate a regression test rule.   |  <code>True</code> |
| <a id="fuzzing_decoration-test_tags"></a>test_tags |  Tags set on the fuzzing regression test.   |  <code>None</code> |


