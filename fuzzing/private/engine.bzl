# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""The implementation of the cc_fuzzing_engine rule."""

CcFuzzingEngineInfo = provider(
    doc = """
Provider for storing the specification of a fuzzing engine.
""",
    fields = {
        "display_name": "A string representing the human-readable name of the fuzzing engine.",
        "cc_library_info": "A CcInfo provider for the C++ library of the fuzzing engine.",
        "runfiles": "The runfiles of the fuzzing engine.",
        "launcher": "A file representing the shell script that launches the fuzz target.",
        "environment": "A dictionary from environment variables to files.",
    },
)

def _cc_fuzzing_engine_impl(ctx):
    if not ctx.attr.display_name:
        fail("The display_name attribute of the rule must not be empty.")

    runfiles = ctx.runfiles()
    env_vars = {}
    for data, env_var in ctx.attr.data.items():
        if env_var:
            if env_var in env_vars:
                fail("Multiple data dependencies map to variable '%s'." % env_var)
            data_files = data.files.to_list()
            if len(data_files) != 1:
                fail("Data dependency for variable '%s' doesn't map to exactly one file." % env_var)
            env_vars[env_var] = data_files[0]
        runfiles = runfiles.merge(data[DefaultInfo].default_runfiles)

    cc_library_info = ctx.attr.library[CcInfo]
    cc_fuzzing_engine_info = CcFuzzingEngineInfo(
        display_name = ctx.attr.display_name,
        cc_library_info = cc_library_info,
        runfiles = runfiles,
        launcher = ctx.file.launcher,
        environment = env_vars,
    )
    return [cc_library_info, cc_fuzzing_engine_info]

cc_fuzzing_engine = rule(
    implementation = _cc_fuzzing_engine_impl,
    doc = """
Specifies a fuzzing engine that can be used to run C++ fuzz targets.
""",
    attrs = {
        "display_name": attr.string(
            doc = "The name of the fuzzing engine, as it should be rendered " +
                  "in human-readable output.",
            mandatory = True,
        ),
        "library": attr.label(
            doc = "A cc_library target that implements the fuzzing engine " +
                  "entry point.",
            mandatory = True,
            providers = [CcInfo],
        ),
        "launcher": attr.label(
            doc = "A shell script that knows how to launch the fuzzing " +
                  "executable based on configuration specified in the environment.",
            mandatory = True,
            allow_single_file = True,
        ),
        "data": attr.label_keyed_string_dict(
            doc = "A dict mapping additional runtime dependencies needed by " +
                  "the fuzzing engine to environment variables that will be " +
                  "available inside the launcher, holding the runtime path " +
                  "to the dependency.",
            allow_files = True,
        ),
    },
    provides = [CcFuzzingEngineInfo],
)
