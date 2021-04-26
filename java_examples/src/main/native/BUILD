load("@rules_cc//cc:defs.bzl", "cc_binary")

cc_binary(
    name = "native",
    srcs = [
        "com_example_JavaNativeFuzzTest.cpp",
        "com_example_JavaNativeFuzzTest.h",
    ],
    linkshared = True,
    visibility = ["//examples/java:__pkg__"],
    deps = [
        ":jni",
    ],
)

# Local JNI headers.
cc_library(
    name = "jni",
    hdrs = [
        ":jni_headers",
    ],
)

filegroup(
    name = "jni_headers",
    srcs = [
        ":jni_header",
        ":jni_md_header",
    ],
)

genrule(
    name = "jni_md_header",
    srcs = select({
        "@platforms//os:osx": ["@bazel_tools//tools/jdk:jni_md_header-darwin"],
        "@platforms//os:windows": ["@bazel_tools//tools/jdk:jni_md_header-windows"],
        "//conditions:default": ["@bazel_tools//tools/jdk:jni_md_header-linux"],
    }),
    outs = ["jni_md.h"],
    cmd = "cp -f $< $@",
)

genrule(
    name = "jni_header",
    srcs = ["@bazel_tools//tools/jdk:jni_header"],
    outs = ["jni.h"],
    cmd = "cp -f $< $@",
)
