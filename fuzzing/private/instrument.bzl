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

"""Primitives for defining fuzzing engine instrumentations."""

load(
    "//fuzzing:instrum_opts.bzl",
    "base_opts",
    "fuzzing_engine_opts",
    "instrumentation_opts",
    "sanitizer_opts",
)

def _merge_opts(left_opts, right_opts):
    return instrumentation_opts(
        copts = left_opts.copts + right_opts.copts,
        linkopts = left_opts.linkopts + right_opts.linkopts,
    )

def _fuzzing_binary_transition_impl(settings, attr):
    opts = instrumentation_opts(
        copts = settings["//command_line_option:copt"],
        linkopts = settings["//command_line_option:linkopt"],
    )
    opts = _merge_opts(opts, base_opts)

    engine = settings["//fuzzing:cc_engine_instrumentation"]
    if engine in fuzzing_engine_opts:
        opts = _merge_opts(opts, fuzzing_engine_opts[engine])
    else:
        fail("unsupported engine instrumentation '%s'" % engine)

    sanitizer = settings["//fuzzing:cc_engine_sanitizer"]
    if sanitizer in sanitizer_opts:
        opts = _merge_opts(opts, sanitizer_opts[sanitizer])
    else:
        fail("unsupported sanitizer '%s'" % sanitizer)

    opts = _merge_opts(opts, instrumentation_opts(
        copts = attr.extra_copts,
        linkopts = attr.extra_linkopts,
    ))

    return {
        "//command_line_option:copt": opts.copts,
        "//command_line_option:linkopt": opts.linkopts,
        # Make sure binaries are built statically, to maximize the scope of the
        # instrumentation.
        "//command_line_option:dynamic_mode": "off",
    }

fuzzing_binary_transition = transition(
    implementation = _fuzzing_binary_transition_impl,
    inputs = [
        "//fuzzing:cc_engine_instrumentation",
        "//fuzzing:cc_engine_sanitizer",
        "//command_line_option:copt",
        "//command_line_option:linkopt",
    ],
    outputs = [
        "//command_line_option:copt",
        "//command_line_option:linkopt",
        "//command_line_option:dynamic_mode",
    ],
)

def _instrumented_fuzzing_binary_impl(ctx):
    output_file = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(
        output = output_file,
        target_file = ctx.executable.binary,
        is_executable = True,
    )
    return [DefaultInfo(
        executable = output_file,
        runfiles = ctx.attr.binary[0][DefaultInfo].default_runfiles,
    )]

instrumented_fuzzing_binary = rule(
    implementation = _instrumented_fuzzing_binary_impl,
    doc = """
Compiles a fuzzing executable according to the specified instrumentation.

The instrumentation is configured through the
`@rules_fuzzing//fuzzing:cc_engine_instrumentation` and
`@rules_fuzzing//fuzzing:cc_engine_sanitizer` flags.

Additional options can be specified using the `extra_copts` and `extra_linkopts`
attributes and are appended to the option lists.
""",
    attrs = {
        "binary": attr.label(
            executable = True,
            doc = "The fuzz test executable to instrument.",
            cfg = fuzzing_binary_transition,
            mandatory = True,
        ),
        "extra_copts": attr.string_list(
            doc = "Extra C++ compilation options appended to the instrumentation.",
        ),
        "extra_linkopts": attr.string_list(
            doc = "Extra C++ linker options appended to the instrumentation.",
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
    executable = True,
)
