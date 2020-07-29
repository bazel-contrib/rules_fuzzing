#
#  Copyright 2020 Google LLC
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

"""This file contains common rules for fuzzing test."""

def _fuzzing_launcher_impl(ctx):
    # Generate a script to launcher the fuzzing test.
    script = ctx.actions.declare_file("%s" % ctx.label.name)

    script_template = """#!/bin/sh
exec {launcher_path} {target_binary_path} --corpus_dir={corpus_dir} "$@"
"""

    script_content = script_template.format(
        launcher_path = ctx.executable._launcher.short_path,
        target_binary_path = ctx.executable.target.short_path,
        corpus_dir = ctx.file.corpus.short_path if ctx.attr.corpus else "",
    )
    ctx.actions.write(script, script_content, is_executable = True)

    # Merge the dependencies.
    runfiles = ctx.attr._launcher[DefaultInfo].default_runfiles
    runfiles = runfiles.merge(ctx.attr.target[DefaultInfo].default_runfiles)
    if ctx.attr.corpus:
        runfiles = runfiles.merge(ctx.attr.corpus[DefaultInfo].default_runfiles)

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
        "target": attr.label(
            executable = True,
            doc = "The fuzzing test to run.",
            cfg = "target",
            mandatory = True,
        ),
        "corpus": attr.label(
            doc = "The target to create a directory containing corpus files.",
            allow_single_file = True,
        ),
    },
    executable = True,
)

def _fuzzing_corpus_impl(ctx):
    corpus_dir = ctx.actions.declare_directory(ctx.attr.name)
    cp_args = ctx.actions.args()

    for input_file in ctx.files.srcs:
        cp_args.add(input_file)

    # Add destination to the arguments
    cp_args.add(corpus_dir.path)

    ctx.actions.run_shell(
        inputs = ctx.files.srcs,
        outputs = [corpus_dir],
        arguments = [cp_args],
        command = "cp $@",
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
        "srcs": attr.label_list(
            doc = "The corpus files for the fuzzing test.",
            allow_files = True,
        ),
    },
)
