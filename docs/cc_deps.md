<a name="#cc_fuzz_test"></a>

## cc_fuzz_test

<pre>
cc_fuzz_test(<a href="#cc_fuzz_test-name">name</a>, <a href="#cc_fuzz_test-corpus">corpus</a>, <a href="#cc_fuzz_test-kwargs">**kwargs</a>)
</pre>

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
| corpus |  A list containing corpus files.   |  <code>None</code> |
| kwargs |  Keyword arguments.   |  none |


