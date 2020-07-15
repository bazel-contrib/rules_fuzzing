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

""" This file contains basic functions for fuzz test. """

load("@rules_cc//cc:defs.bzl", "cc_test")

def _cc_fuzz_run_impl(ctx):
    # Generate a script to launcher the fuzzing test
    script = ctx.actions.declare_file("%s" % ctx.label.name)

    # This command is absolutely not what we are looking for,
    # but without timeout here, the bazel run never exists.
    # What is wrong here?
    script_template = """#!/bin/bash
timeout 10 {launcher} {target}
"""

    script_content = script_template.format(
        launcher =
            ctx.attr._launcher[DefaultInfo].files_to_run.executable.short_path,
        target =
            ctx.attr.dep[DefaultInfo].files_to_run.executable.short_path,
    )
    ctx.actions.write(script, script_content, is_executable = True)

    # Merge the two dependencies
    runfiles = ctx.attr._launcher[DefaultInfo].default_runfiles
    runfiles = runfiles.merge(ctx.attr.dep[DefaultInfo].default_runfiles)

    return [DefaultInfo(executable = script, runfiles = runfiles)]

# What should the argument be? How to pass timeout_secs?
cc_fuzz_run = rule(
    implementation = _cc_fuzz_run_impl,
    attrs = {
        # The launcher script to start fuzzing test
        "_launcher": attr.label(
            default = Label("//fuzzing/tools:launcher"),
            executable = True,
            cfg = "host",
        ),
        # The _fuzz_test executable to run
        "dep": attr.label(
            executable = True,
            cfg = "host",
        ),
    },
    executable = True,
)

def cc_fuzz_test(
        name,
        srcs,
        copts = [],
        linkopts = [],
        deps = [],
        tags = [],
        visibility = None):
    """ At present this cc_fuzz_test is just a wrapper of cc_test """

    cc_test(
        name = name,
        srcs = srcs,
        copts = ["-fsanitize=fuzzer"] + copts,
        linkopts = ["-fsanitize=fuzzer"] + linkopts,
        deps = deps,
        tags = tags + ["fuzz_test"],
        visibility = visibility,
    )

    cc_fuzz_run(
        name = name + "_run",
        dep = name,
        # Since the script depends on the _fuzz_test above, which is a cc_test,
        # this attribute must be set
        testonly = True,
    )
