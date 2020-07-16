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
exec {launcher_path} {target_binary_path} "$@"
"""

    script_content = script_template.format(
        launcher_path = ctx.executable._launcher.short_path,
        target_binary_path = ctx.executable.target.short_path,
    )
    ctx.actions.write(script, script_content, is_executable = True)

    # Merge the two dependencies.
    runfiles = ctx.attr._launcher[DefaultInfo].default_runfiles
    runfiles = runfiles.merge(ctx.attr.target[DefaultInfo].default_runfiles)

    return [DefaultInfo(executable = script, runfiles = runfiles)]

fuzzing_launcher = rule(
    implementation = _fuzzing_launcher_impl,
    doc = """
Rule for creating a script to run the fuzzing test
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
    },
    executable = True,
)

def _fuzzing_corpus_impl(ctx):
    dir = ctx.actions.declare_directory(ctx.attr.name)
    command = "cp "

    # Merge the file path to the cp command
    for f in ctx.files.srcs:
        command += f.short_path + " "
    ctx.actions.run_shell(
        inputs = ctx.files.srcs,
        outputs = [dir],
        command = command + dir.path,
    )

    return [DefaultInfo(files = depset([dir]))]

fuzzing_corpus = rule(
    implementation = _fuzzing_corpus_impl,
    doc = """
This rule provides a <name>_corpus directory collecting all the corpora files 
specified in the corpus attribute of the cc_fuzz_test rule, 
and a <name>_corpus.zip with the corpus files as a ZIP archive
""",
    attrs = {
        "srcs": attr.label_list(
            doc = "The corpus files for the fuzzing test.",
            allow_files = True,
        ),
    },
)
