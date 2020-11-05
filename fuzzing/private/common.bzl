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

"""Common building blocks for fuzz test definitions."""

load("//fuzzing/private:engine.bzl", "CcFuzzingEngineInfo")

def _fuzzing_launcher_script(ctx):
    engine_info = ctx.attr.engine[CcFuzzingEngineInfo]
    script = ctx.actions.declare_file(ctx.label.name)

    script_template = """
{environment}
echo "Launching {binary_path} as a {engine_name} fuzz test..."
exec "{launcher}" \
    --engine_launcher="{engine_launcher}" \
    --binary_path="{binary_path}" \
    --corpus_dir="{corpus_dir}" \
    --dictionary_path="{dictionary_path}" \
    "$@"
"""
    script_content = script_template.format(
        environment = "\n".join([
            "export %s='%s'" % (var, file.short_path)
            for var, file in engine_info.environment.items()
        ]),
        launcher = ctx.executable._launcher.short_path,
        binary_path = ctx.executable.binary.short_path,
        engine_launcher = engine_info.launcher.short_path,
        engine_name = engine_info.display_name,
        corpus_dir = ctx.file.corpus.short_path if ctx.attr.corpus else "",
        dictionary_path = ctx.file.dictionary.short_path if ctx.attr.dictionary else "",
    )
    ctx.actions.write(script, script_content, is_executable = True)
    return script

def _fuzzing_launcher_impl(ctx):
    script = _fuzzing_launcher_script(ctx)

    engine_info = ctx.attr.engine[CcFuzzingEngineInfo]
    runfiles = ctx.runfiles(files = [engine_info.launcher])
    runfiles = runfiles.merge(engine_info.runfiles)
    runfiles = runfiles.merge(ctx.attr._launcher[DefaultInfo].default_runfiles)
    runfiles = runfiles.merge(ctx.attr.binary[DefaultInfo].default_runfiles)
    if ctx.attr.corpus:
        runfiles = runfiles.merge(ctx.attr.corpus[DefaultInfo].default_runfiles)
    if ctx.attr.dictionary:
        runfiles = runfiles.merge(ctx.attr.dictionary[DefaultInfo].default_runfiles)

    return [DefaultInfo(executable = script, runfiles = runfiles)]

fuzzing_launcher = rule(
    implementation = _fuzzing_launcher_impl,
    doc = """
Rule for creating a script to run the fuzzing test.
""",
    attrs = {
        "_launcher": attr.label(
            default = Label("//fuzzing/tools:launcher"),
            doc = "The launcher script to start the fuzzing test.",
            executable = True,
            cfg = "host",
        ),
        "engine": attr.label(
            doc = "The specification of the fuzzing engine to execute.",
            providers = [CcFuzzingEngineInfo],
            mandatory = True,
        ),
        "binary": attr.label(
            executable = True,
            doc = "The executable of the fuzz test to run.",
            cfg = "target",
            mandatory = True,
        ),
        "corpus": attr.label(
            doc = "A directory of corpus files to use as input seeds.",
            allow_single_file = True,
        ),
        "dictionary": attr.label(
            doc = "A dictionary file to use in fuzzing runs.",
            allow_single_file = True,
        ),
    },
    executable = True,
)

def _fuzzing_corpus_impl(ctx):
    corpus_dir = ctx.actions.declare_directory(ctx.attr.name)
    cp_args = ctx.actions.args()
    cp_args.add_joined("--corpus_list", ctx.files.srcs, join_with = ",")
    cp_args.add("--output_dir=" + corpus_dir.path)

    ctx.actions.run(
        inputs = ctx.files.srcs,
        outputs = [corpus_dir],
        arguments = [cp_args],
        executable = ctx.executable._corpus_tool,
    )

    return [DefaultInfo(
        runfiles = ctx.runfiles(files = [corpus_dir]),
        files = depset([corpus_dir]),
    )]

fuzzing_corpus = rule(
    implementation = _fuzzing_corpus_impl,
    doc = """
This rule provides a <name>_corpus directory collecting all the corpora files 
specified in the srcs attribute.
""",
    attrs = {
        "_corpus_tool": attr.label(
            default = Label("//fuzzing/tools:make_corpus_dir"),
            doc = "The tool script to copy and rename the corpus.",
            executable = True,
            cfg = "host",
        ),
        "srcs": attr.label_list(
            doc = "The corpus files for the fuzzing test.",
            allow_files = True,
        ),
    },
)

def _fuzzing_dictionary_impl(ctx):
    output_dict = ctx.actions.declare_file(ctx.attr.output)
    args = ctx.actions.args()
    args.add_joined("--dict_list", ctx.files.dicts, join_with = ",")
    args.add("--output_file=" + output_dict.path)

    ctx.actions.run(
        inputs = ctx.files.dicts,
        outputs = [output_dict],
        arguments = [args],
        executable = ctx.executable._validation_tool,
    )

    runfiles = ctx.runfiles(files = [output_dict])

    return [DefaultInfo(
        runfiles = runfiles,
        files = depset([output_dict]),
    )]

fuzzing_dictionary = rule(
    implementation = _fuzzing_dictionary_impl,
    doc = """
Rule to validate the fuzzing dictionaries and output a merged dictionary.
""",
    attrs = {
        "_validation_tool": attr.label(
            default = Label("//fuzzing/tools:validate_dict"),
            doc = "The tool script to validate and merge the dictionaries.",
            executable = True,
            cfg = "host",
        ),
        "dicts": attr.label_list(
            doc = "The fuzzing dictionaries.",
            allow_files = True,
            mandatory = True,
        ),
        "output": attr.string(
            doc = "The name of the merged dictionary.",
            mandatory = True,
        ),
    },
)
