# Space Rangers 1 - Decompilation

*Космические рейнджеры*

A decompilation project recovering the game’s Delphi source code. The recovered
source compiles to a **byte-for-byte identical** `Rangers.exe`.

Targets version **1.7.2**, English Steam release (2,371,072 bytes).

SHA-256:

```text
8936d04b0ebf652fe9b590e82e9e83df21550488654e28032978d41c0fff9b00
```

**AI disclosure:** This decompilation project was carried out almost entirely by
GPT-6 Astra in Codex, with some human steering. Opus 5.5 was also used for some
source cleanup.

Install the [prerequisites](docs/development.md#setup), then run:

```sh
./decomp setup
./decomp verify
```

Setup downloads and prepares the Delphi toolchain. Verification checks the whole
executable against the original SHA-256.

[Development and progress reports](docs/development.md) ·
[Pascal annotations](docs/declarations.md)

See also:

- [okgf](https://github.com/pakompom/okgf) - a portable C reimplementation of
  `okgf.dll`, with support for Space Rangers 1.
- [SpaceRangersHD_decomp](https://github.com/pakompom/SpaceRangersHD_decomp) -
  the companion decompilation of *Space Rangers HD: A War Apart*.

Unofficial; not affiliated with the game's developers or publisher.
See [rights and attribution](NOTICE.md) and the [tooling license](LICENSE).
