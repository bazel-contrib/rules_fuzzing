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

# Lint as: python3
"""Unit tests for make_corpus_dir.py.

These tests drive the tool through ``--corpus_list_file`` with cleaned,
workspace-relative paths, matching how ``fuzzing_corpus`` invokes it (see
``_fuzzing_corpus_impl`` in fuzzing/private/common.bzl, which passes
``add_all(ctx.files.srcs)`` via a multiline param file).
"""

import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


def resolve_script_path():
    candidates = [Path(__file__).with_name("make_corpus_dir.py")]
    test_workspace = os.environ.get("TEST_WORKSPACE")
    if test_workspace:
        test_srcdir = os.environ.get("TEST_SRCDIR")
        if test_srcdir:
            candidates.append(
                Path(test_srcdir) / test_workspace / "fuzzing" / "tools" /
                "make_corpus_dir.py")
        runfiles_dir = os.environ.get("RUNFILES_DIR")
        if runfiles_dir:
            candidates.append(
                Path(runfiles_dir) / test_workspace / "fuzzing" / "tools" /
                "make_corpus_dir.py")

    for candidate in candidates:
        if candidate.is_file():
            return candidate

    manifest_file = os.environ.get("RUNFILES_MANIFEST_FILE")
    if manifest_file:
        try:
            workspace_match = None
            main_match = None
            with open(manifest_file, "r", encoding="utf-8") as manifest:
                for line in manifest:
                    entry = line.rstrip("\n")
                    if not entry:
                        continue
                    logical_path, separator, real_path = entry.partition(" ")
                    if not separator:
                        continue
                    normalized_path = logical_path.replace("\\", "/")
                    if not normalized_path.endswith(
                            "fuzzing/tools/make_corpus_dir.py"):
                        continue
                    candidate = Path(real_path)
                    if not candidate.is_file():
                        continue
                    if test_workspace and normalized_path.startswith(
                            f"{test_workspace}/"):
                        workspace_match = candidate
                        break
                    if normalized_path.startswith("_main/") and not main_match:
                        main_match = candidate
            if workspace_match:
                return workspace_match
            if main_match:
                return main_match
        except OSError:
            pass

    raise FileNotFoundError(
        "could not resolve make_corpus_dir.py in test runfiles")


SCRIPT_PATH = resolve_script_path()


class MakeCorpusDirTest(unittest.TestCase):

    def run_tool_with_corpus_list_file(self, corpus_paths, cwd):
        """Invokes the tool the way fuzzing_corpus does: a param file of
        cleaned, workspace-relative paths passed via --corpus_list_file."""
        params = cwd / "corpus_params.txt"
        params.write_text("\n".join(corpus_paths) + "\n", encoding="utf-8")
        return subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                f"--corpus_list_file={params.name}",
                "--output_dir=out",
            ],
            cwd=str(cwd),
            text=True,
            capture_output=True,
            check=False,
        )

    def _write(self, root, rel_path, contents):
        path = root / rel_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents, encoding="utf-8")
        return str(rel_path).replace(os.sep, "/")

    def test_copies_distinct_files_without_collision(self):
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            a = self._write(tmp, Path("corpus") / "a.txt", "A")
            b = self._write(tmp, Path("corpus") / "nested" / "b.txt", "B")

            result = self.run_tool_with_corpus_list_file([a, b], cwd=tmp)

            self.assertEqual(result.returncode, 0, msg=result.stderr)
            copied = [p for p in (tmp / "out").iterdir() if p.is_file()]
            self.assertEqual(len(copied), 2)
            self.assertEqual(
                sorted(p.read_text(encoding="utf-8") for p in copied),
                ["A", "B"])

    def test_flatten_collision_is_disambiguated(self):
        # Reachable collision: "corpus/a/b.txt" and "corpus/a-b.txt" both
        # flatten to "corpus-a-b.txt" under replace("/", "-"). On current main
        # this aborts the action with "ERROR: file ... existed." / return -1.
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            nested = self._write(tmp, Path("corpus") / "a" / "b.txt", "NESTED")
            flat = self._write(tmp, Path("corpus") / "a-b.txt", "FLAT")

            result = self.run_tool_with_corpus_list_file([nested, flat], cwd=tmp)

            self.assertEqual(result.returncode, 0, msg=result.stderr)
            copied = [p for p in (tmp / "out").iterdir() if p.is_file()]
            self.assertEqual(len(copied), 2)
            self.assertEqual(
                sorted(p.read_text(encoding="utf-8") for p in copied),
                ["FLAT", "NESTED"])

    def test_flatten_collision_variant_is_disambiguated(self):
        # A second reachable variant where the "/" boundary in one path aligns
        # with a literal "-" in another: "a/b/c.txt" and "a-b/c.txt" both
        # flatten to "a-b-c.txt".
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            first = self._write(tmp, Path("a") / "b" / "c.txt", "FIRST")
            second = self._write(tmp, Path("a-b") / "c.txt", "SECOND")

            result = self.run_tool_with_corpus_list_file(
                [first, second], cwd=tmp)

            self.assertEqual(result.returncode, 0, msg=result.stderr)
            copied = [p for p in (tmp / "out").iterdir() if p.is_file()]
            self.assertEqual(len(copied), 2)
            self.assertEqual(
                sorted(p.read_text(encoding="utf-8") for p in copied),
                ["FIRST", "SECOND"])


if __name__ == "__main__":
    unittest.main()
