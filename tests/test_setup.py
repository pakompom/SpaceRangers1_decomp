"""Input integrity and isolation for the standalone compiler setup."""

import hashlib
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from types import SimpleNamespace

spec = importlib.util.spec_from_file_location("decomp_setup", Path(__file__).resolve().parents[1] / "toolchain/setup.py")
setup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup)


class CompilerInputs(unittest.TestCase):
    def test_compiler_is_copied_and_altered_library_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            original = root / "original"
            files = {"bin/DCC32.EXE": b"compiler", "lib/System.dcu": b"library"}
            for name, data in files.items():
                path = original / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(data)
            inputs = {"compiler": {"version": "test", "files": {
                name: hashlib.sha256(data).hexdigest() for name, data in files.items()
            }}}
            with patch.object(setup, "LOCAL", root / "local"), patch.object(setup, "INPUTS", inputs):
                target = setup.compiler(original)
                for name, data in files.items():
                    self.assertEqual((target / name).read_bytes(), data)
                    self.assertFalse((target / name).samefile(original / name))
                (target / "lib/System.dcu").write_bytes(b"altered")
                with self.assertRaisesRegex(RuntimeError, "Input checksum failed"):
                    setup.compiler(None)

    def test_missing_input_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            inputs = {"compiler": {"version": "test", "files": {"bin/DCC32.EXE": "0" * 64}}}
            with patch.object(setup, "INPUTS", inputs):
                with self.assertRaisesRegex(RuntimeError, "Missing Delphi test input"):
                    setup.compiler(Path(directory))

    def test_only_selected_files_are_copied_and_stale_files_are_trashed(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            original = root / "original"
            target = root / "local/toolchains/delphi7"
            for base in (original, target):
                (base / "bin").mkdir(parents=True)
                (base / "bin/DCC32.EXE").write_bytes(b"compiler")
                (base / "bin/DCC70.DLL").write_bytes(b"unused IDE compiler")
            inputs = {"compiler": {"version": "test", "files": {
                "bin/DCC32.EXE": hashlib.sha256(b"compiler").hexdigest()
            }}}
            with (patch.object(setup, "LOCAL", root / "local"),
                  patch.object(setup, "INPUTS", inputs), patch.object(setup, "run") as run):
                self.assertEqual(setup.compiler(original), target)
                run.assert_called_once_with("trash", target / "bin/DCC70.DLL")
                self.assertTrue((original / "bin/DCC70.DLL").exists())
                (original / "bin/DCC32.EXE").write_bytes(b"altered")
                run.reset_mock()
                with self.assertRaisesRegex(RuntimeError, "Input checksum failed"):
                    setup.compiler(original)
                run.assert_not_called()

    def test_archive_extraction_selects_manifest_paths(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            files = {"bin/DCC32.EXE": b"compiler", "lib/System.dcu": b"library"}
            inputs = {"compiler": {"version": "test", "files": {
                name: hashlib.sha256(data).hexdigest() for name, data in files.items()
            }}}
            prefix = "Install/program files/Borland/Delphi7/"

            def extract(args, **kwargs):
                self.assertIn("-ssc-", args)
                self.assertEqual(args[-2:], [prefix + name for name in files])
                for name, data in files.items():
                    path = root / "extract/delphi7" / prefix / name
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(data)
                return SimpleNamespace(returncode=2)

            with (patch.object(setup, "LOCAL", root), patch.object(setup, "INPUTS", inputs),
                  patch.object(setup, "download", return_value=root / "compiler.iso"),
                  patch.object(setup, "sevenzip", return_value="7zz"),
                  patch.object(setup.subprocess, "run", side_effect=extract)):
                target = setup.compiler(None)
                self.assertEqual(set(target.rglob("*.dcu")), {target / "lib/System.dcu"})
