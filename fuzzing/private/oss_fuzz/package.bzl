# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Rule for packaging fuzz tests in the expected OSS-Fuzz format."""

load("//fuzzing/private:binary.bzl", "CcFuzzingBinaryInfo")

def _oss_fuzz_package_impl(ctx):
    output_archive = ctx.actions.declare_file(ctx.label.name + ".tar")
    binary_info = ctx.attr.binary[CcFuzzingBinaryInfo]

    action_inputs = [binary_info.binary_file]
    if binary_info.corpus_dir:
        action_inputs.append(binary_info.corpus_dir)
    if binary_info.dictionary_file:
        action_inputs.append(binary_info.dictionary_file)
    ctx.actions.run_shell(
        outputs = [output_archive],
        inputs = action_inputs,
        command = """
            declare -r STAGING_DIR="$(mktemp --directory -t oss-fuzz-pkg.XXXXXXXXXX)"
            function cleanup() {{
                rm -rf "$STAGING_DIR"
            }}
            trap cleanup EXIT
            ln -s "$(pwd)/{binary_path}" "$STAGING_DIR/{base_name}"
            if [[ -n "{corpus_dir}" ]]; then
                pushd "{corpus_dir}" >/dev/null
                zip --quiet -r "$STAGING_DIR/{base_name}_seed_corpus.zip" ./*
                popd >/dev/null
            fi
            if [[ -n "{dictionary_path}" ]]; then
                ln -s "$(pwd)/{dictionary_path}" "$STAGING_DIR/{base_name}.dict"
            fi
            tar -chf "{output}" -C "$STAGING_DIR" .
        """.format(
            base_name = ctx.attr.base_name,
            binary_path = binary_info.binary_file.path,
            corpus_dir = binary_info.corpus_dir.path if binary_info.corpus_dir else "",
            dictionary_path = binary_info.dictionary_file.path if binary_info.dictionary_file else "",
            output = output_archive.path,
        ),
    )
    return [DefaultInfo(files = depset([output_archive]))]

oss_fuzz_package = rule(
    implementation = _oss_fuzz_package_impl,
    doc = """
Packages a fuzz test in a TAR archive compatible with the OSS-Fuzz format.

> NOTE: The current implementation does not yet support packaging the
> binary runfiles.
""",
    attrs = {
        "binary": attr.label(
            executable = True,
            doc = "The fuzz test executable.",
            providers = [CcFuzzingBinaryInfo],
            mandatory = True,
            cfg = "target",
        ),
        "base_name": attr.string(
            doc = "The base name of the fuzz test used to form the file names " +
                  "in the OSS-Fuzz output.",
            mandatory = True,
        ),
    },
)
