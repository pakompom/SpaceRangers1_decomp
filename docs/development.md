# Development

## Setup

Python 3.11+, Rust 1.90+, Clang, 7-Zip and `trash` are required.
Linux needs Wine with 32-bit support and the `ru_RU.UTF-8` locale.
macOS setup downloads Wine; Apple Silicon also needs Rosetta 2.

Ubuntu 24.04 (x86-64):

```sh
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install --no-install-recommends build-essential clang python3 python3-venv p7zip-full trash-cli wine wine32:i386 xvfb xauth locales
sudo locale-gen ru_RU.UTF-8
```

macOS, with Homebrew and the command-line developer tools:

```sh
brew install python rust sevenzip trash
```

Run `./decomp setup`. Downloads and generated files go in `.local/`; Cargo uses
`target/`. Both are excluded from Git. `toolchain/inputs.json` pins the inputs.
An existing Delphi 7 installation can be supplied with `--compiler-dir PATH`.

## Build and match

```sh
./decomp check
./decomp verify
```

`check` validates the source. `verify` builds `.local/build/layout/Rangers.exe`
and checks the complete file against the target SHA-256. It needs no original
executable, game data or IDA database. On headless Linux, use
`xvfb-run -a ./decomp verify`.

For per-function comparisons, place the original at `game/Rangers.exe` and run
`./decomp match --all`. A routine name or source path narrows the selection.
`./decomp report` verifies the executable and writes `.local/report.json` in
objdiff v2 format. Its totals cover recovered routine entry chunks, excluding
shared tails, libraries and data.

The compiler worker starts automatically. Run `./decomp worker stop` after
changing compiler inputs or Wine. `./decomp --help` lists the commands.

## Source and compiler

`source/` groups annotated Delphi units by subsystem. Preserve native behavior
and check changes with `check` and `verify`. See [declarations.md](declarations.md)
for annotations. Compiler controls are in `tests/delphi/`.

The build uses Delphi 7 Enterprise 7.0.4.453. Setup extracts the pinned compiler
and libraries without running an installer. The hooks and manifests in
`toolchain/delphi/` reproduce unit order, startup metadata, reference cells and
timestamps. One scoped compatibility hook initializes an undefined compiler
field for `GetMusicFile`, reproducing its native exception-frame teardown.
Compiler preparation needs no game executable; the output is not post-processed.

## Optional IDA integration

Save the original executable's IDA database as `game/Rangers.i64`, or set
`project.database`. Close it before batch use. IDA 9.x with IDAPython is required;
set `IDA` to its batch executable or put `idat` on PATH.

```sh
./decomp sync diff
./decomp sync apply
./decomp index
```

`diff` previews annotations; `apply` saves them. `index` refreshes
`.local/native_ranges.json`, which overrides the bundled reference.
