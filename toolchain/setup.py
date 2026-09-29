#!/usr/bin/env python3
"""Prepare the independent Delphi 7 matching toolchain without running installers."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
LOCAL = ROOT / ".local"
INPUTS = json.loads((ROOT / "toolchain/inputs.json").read_text())


def sha256(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def checked(path, expected):
    if sha256(path) != expected:
        raise RuntimeError(f"Input checksum failed: {path}")
    return path


def download(spec, name):
    path = LOCAL / "downloads" / name
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and sha256(path) == spec["sha256"]:
        return path
    temporary = path.with_suffix(path.suffix + ".partial")
    print(f"Downloading {name}", flush=True)
    request = urllib.request.Request(spec["url"], headers={"User-Agent": "SpaceRangers1-decomp-setup/1"})
    with urllib.request.urlopen(request, timeout=60) as source, temporary.open("wb") as output:
        shutil.copyfileobj(source, output)
    checked(temporary, spec["sha256"])
    temporary.replace(path)
    return path


def run(*args):
    subprocess.run([str(arg) for arg in args], check=True, cwd=ROOT)


def sevenzip():
    for name in ("7zz", "7z"):
        if executable := shutil.which(name):
            return executable
    raise RuntimeError("7-Zip missing; see docs/development.md#setup")


def compiler(directory):
    spec = INPUTS["compiler"]
    target = LOCAL / "toolchains/delphi7"
    if directory is None and all((target / name).is_file() for name in spec["files"]):
        directory = target
    if directory is None:
        archive = download(spec, "delphi_7_ent_en.iso")
        staging = LOCAL / "extract/delphi7"
        prefix = "Install/program files/Borland/Delphi7/"
        selected = [prefix + name for name in spec["files"]]
        result = subprocess.run(
            [sevenzip(), "x", "-y", "-ssc-", "-bso0", "-bsp0", str(archive),
             "-o" + str(staging), *selected],
            cwd=ROOT,
        )
        # The original ISO has malformed big-endian headers. Validate every
        # selected output even when 7-Zip reports this known header error.
        if result.returncode not in (0, 1, 2):
            raise RuntimeError(f"7-Zip extraction failed: {result.returncode}")
        directory = staging / prefix
    if (target / "bin/dcc32.cfg").exists() or (target / "bin/DCC32.CFG").exists():
        raise RuntimeError("Remove local dcc32.cfg overrides before building")
    paths = {str(p.relative_to(directory)).lower(): p for p in directory.rglob("*") if p.is_file()}
    sources = []
    for name, expected in spec["files"].items():
        source = paths.get(name.lower())
        if source is None:
            raise RuntimeError(f"Missing Delphi {spec['version']} input: {name}")
        checked(source, expected)
        sources.append((name, source))
    for name, source in sources:
        destination = target / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        if source.resolve() != destination.resolve():
            shutil.copy2(source, destination)
    selected = {name.lower() for name in spec["files"]}
    unused = [path for path in target.rglob("*") if path.is_file()
              and str(path.relative_to(target)).lower() not in selected]
    if unused:
        run("trash", *unused)
    return target


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--compiler-dir", type=Path, help="Existing Delphi 7 root containing bin/ and lib/; verified and copied locally")
    args = parser.parse_args()
    LOCAL.mkdir(exist_ok=True)
    python = LOCAL / "python/bin/python3"
    if Path(sys.prefix).resolve() != python.parent.parent.resolve():
        if not python.exists():
            run(sys.executable, "-m", "venv", python.parent.parent)
        wheel = download(INPUTS["pefile"], INPUTS["pefile"]["filename"])
        run(python, "-m", "pip", "install", "--disable-pip-version-check", "--no-cache-dir", "--no-index", "--no-deps", wheel)
        os.execv(str(python), [str(python), str(Path(__file__)), *sys.argv[1:]])
    for command in ("cargo", "clang"):
        if not shutil.which(command):
            raise RuntimeError(f"{command} missing; see docs/development.md#setup")
    if sys.platform == "darwin" and not os.environ.get("WINE"):
        wine = download(INPUTS["wine_macos"], "wine-macos.tar.xz")
        destination = LOCAL / "wine"
        destination.mkdir(exist_ok=True)
        with tarfile.open(wine) as archive:
            archive.extractall(destination, filter="data")
    compiler(args.compiler_dir.resolve() if args.compiler_dir else None)
    run(python, ROOT / "toolchain/delphi/prepare.py")
    run("cargo", "build", "--locked", "--release", "--bin", "decomp")
    print("Toolchain ready. Run ./decomp verify", flush=True)


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        sys.exit(f"Setup failed: {error}")
