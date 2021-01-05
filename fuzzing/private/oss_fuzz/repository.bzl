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

"""Repository rule for configuring the OSS-Fuzz engine and instrumentation."""

def _to_list_repr(elements):
    return ", ".join([repr(element) for element in elements])

def _extract_build_params(
        repository_ctx,
        fuzzing_engine_library,
        cflags,
        cxxflags):
    stub_srcs = []
    stub_linkopts = []
    instrum_conlyopts = []
    instrum_cxxopts = []

    if fuzzing_engine_library:
        if fuzzing_engine_library.startswith("-"):
            # This is actually a flag, add it to the linker flags.
            stub_linkopts.append(fuzzing_engine_library)
        elif fuzzing_engine_library.endswith(".a"):
            repository_ctx.symlink(
                repository_ctx.path(fuzzing_engine_library),
                "oss_fuzz_engine.a",
            )
            stub_srcs.append("oss_fuzz_engine.a")
        else:
            fail("Unsupported $LIB_FUZZING_ENGINE value '%s'" % fuzzing_engine_library)
    for cflag in cflags:
        # Skip the fuzzing build more flag, since it is separately controlled
        # by the --//fuzzing:cc_fuzzing_build_mode configuration flag.
        if cflag == "-DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION":
            continue
        instrum_conlyopts.append(cflag)
        if cflag not in stub_linkopts:
            stub_linkopts.append(cflag)
    for cxxflag in cxxflags:
        if cxxflag == "-DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION":
            continue
        instrum_cxxopts.append(cxxflag)
        if cxxflag not in stub_linkopts:
            stub_linkopts.append(cxxflag)

    return struct(
        stub_srcs = stub_srcs,
        stub_linkopts = stub_linkopts,
        instrum_conlyopts = instrum_conlyopts,
        instrum_cxxopts = instrum_cxxopts,
    )

def _oss_fuzz_repository(repository_ctx):
    environ = repository_ctx.os.environ
    fuzzing_engine_library = environ.get("LIB_FUZZING_ENGINE")
    cflags = environ.get("CFLAGS", "").split(" ")
    cxxflags = environ.get("CXXFLAGS", "").split(" ")

    build_params = _extract_build_params(
        repository_ctx,
        fuzzing_engine_library,
        cflags,
        cxxflags,
    )

    repository_ctx.template(
        "BUILD",
        repository_ctx.path(Label("@rules_fuzzing//fuzzing/private/oss_fuzz:BUILD.tpl")),
        {
            "%{stub_srcs}": _to_list_repr(build_params.stub_srcs),
            "%{stub_linkopts}": _to_list_repr(build_params.stub_linkopts),
        },
    )
    repository_ctx.template(
        "instrum.bzl",
        repository_ctx.path(Label("@rules_fuzzing//fuzzing/private/oss_fuzz:instrum.bzl.tpl")),
        {
            "%{conlyopts}": _to_list_repr(build_params.instrum_conlyopts),
            "%{cxxopts}": _to_list_repr(build_params.instrum_cxxopts),
        },
    )
    repository_ctx.file(
        "oss_fuzz_launcher.sh",
        "echo 'The OSS-Fuzz engine is not meant to be executed.'; exit 1",
    )

oss_fuzz_repository = repository_rule(
    implementation = _oss_fuzz_repository,
    environ = [
        "LIB_FUZZING_ENGINE",
        "CFLAGS",
        "CXXFLAGS",
        "SANITIZER",
    ],
    local = True,
    doc = """
Generates a repository containing an OSS-Fuzz fuzzing engine defintion.

The fuzzing engine is defined in the //:oss_fuzz_engine target.
""",
)
