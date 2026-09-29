"""Prepare Delphi 7 with SR1 link metadata and one constrained IR initialization.

Run from the repository root: .local/python/bin/python3 toolchain/delphi/prepare.py
"""

from pathlib import Path
import json
import shutil
import struct
import subprocess

import pefile


def align(value, alignment):
    return (value + alignment - 1) & -alignment


def main():
    here = Path(__file__).resolve().parent
    root = here.parents[1]
    source = root / ".local/toolchains/delphi7/bin/DCC32.EXE"
    output = root / ".local/toolchains/delphi7-ordered/DCC32.EXE"
    data = bytearray(source.read_bytes())
    pe = pefile.PE(data=data)
    call_rva = 0x24AD9
    call = pe.get_offset_from_rva(call_rva)
    assert data[call : call + 5] == bytes.fromhex("e8 12 f7 ff ff"), "Expected stock D7 7.0.4.453"
    assert pe.OPTIONAL_HEADER.ImageBase == 0x400000
    rva = align(pe.sections[-1].VirtualAddress + pe.sections[-1].Misc_VirtualSize, pe.OPTIONAL_HEADER.SectionAlignment)
    raw = align(len(data), pe.OPTIONAL_HEADER.FileAlignment)
    rows = [
        line.split() for line in (here / "unit-order.tsv").read_text().splitlines() if line and not line.startswith("#")
    ]
    names = [row[1] for row in rows]
    assert len(names) == len(set(names)) == 323
    assembly = (here / "unit_order.s").read_text().replace("HOOK_RVA", str(rva))
    assembly += "".join(" .asciz " + json.dumps(name) + "\n" for name in names) + " .byte 0\n"
    metadata = [
        line.split()
        for line in (here / "metadata-order.tsv").read_text().splitlines()
        if line and not line.startswith("#")
    ]
    initializers = [None] * len(metadata)
    for i, (index, name) in enumerate(metadata):
        initializers[int(index)] = i
    assert None not in initializers and len(set(initializers)) == len(names)
    assembly += (
        (here / "metadata_order.s").read_text().replace("HOOK_RVA", str(rva)).replace("META_COUNT", str(len(metadata)))
    )
    assembly += "\npackage_keys:\n" + "".join(f" .long {rva}+meta_u{i}-start\n" for i in range(len(metadata)))
    assembly += "init_keys:\n" + "".join(f" .long {rva}+meta_u{i}-start\n" for i in initializers)
    assembly += "".join(f"meta_u{i}: .asciz " + json.dumps(name) + "\n" for i, (index, name) in enumerate(metadata))
    references = [
        int(line, 16)
        for line in (here / "reference-order.tsv").read_text().splitlines()
        if line and not line.startswith("#")
    ]
    assert len(references) == len(set(references)) == 687
    assembly += (
        (here / "reference_order.s")
        .read_text()
        .replace("HOOK_RVA", str(rva))
        .replace("REF_COUNT", str(len(references)))
        .replace("REF_BYTES", str(4 * len(references)))
    )
    assembly += "".join(f" .long 0x{target:08x}\n" for target in references) + " .long 0\n"
    assembly += (here / "build_metadata.s").read_text().replace("HOOK_RVA", str(rva))
    assembly += (here / "music_ir.s").read_text().replace("HOOK_RVA", str(rva))
    output.parent.mkdir(parents=True, exist_ok=True)
    asm = output.parent / "unit_order.s"
    obj = output.parent / "unit_order.obj"
    asm.write_text(assembly)
    subprocess.run(["clang", "-target", "i686-pc-windows-msvc", "-c", str(asm), "-o", str(obj)], check=True)
    coff = obj.read_bytes()
    header = 20 + struct.unpack_from("<H", coff, 16)[0]
    assert coff[header : header + 8].rstrip(b"\0") == b".text"
    assert struct.unpack_from("<H", coff, header + 32)[0] == 0, "Unresolved hook relocation"
    length, pointer = struct.unpack_from("<II", coff, header + 16)
    code = coff[pointer : pointer + length]
    symbol_table, symbol_count = struct.unpack_from("<II", coff, 8)
    hooks = {}
    for i in range(symbol_count):
        entry = symbol_table + 18 * i
        name = coff[entry : entry + 8].rstrip(b"\0")
        if name in (b"meta_ini", b"meta_pkg", b"ref_sort", b"ref_put", b"rs_time", b"music_ir"):
            hooks[name] = struct.unpack_from("<I", coff, entry + 8)[0]
    size = align(len(code), pe.OPTIONAL_HEADER.FileAlignment)
    section = pe.sections[-1].get_file_offset() + 40
    assert section + 40 <= pe.sections[0].PointerToRawData
    data[section : section + 40] = struct.pack(
        "<8sIIIIIIHHI", b".lnkord\0", len(code), rva, size, raw, 0, 0, 0, 0, 0x60000020
    )
    struct.pack_into(
        "<H", data, pe.FILE_HEADER.get_field_absolute_offset("NumberOfSections"), pe.FILE_HEADER.NumberOfSections + 1
    )
    for field, value in [
        ("SizeOfImage", align(rva + len(code), pe.OPTIONAL_HEADER.SectionAlignment)),
        ("SizeOfCode", pe.OPTIONAL_HEADER.SizeOfCode + size),
    ]:
        struct.pack_into("<I", data, pe.OPTIONAL_HEADER.get_field_absolute_offset(field), value)
    data[call : call + 5] = b"\xe8" + struct.pack("<i", rva - call_rva - 5)
    for site_rva, original, hook in [
        (0xFB81, 0xF710, b"meta_ini"),
        (0xFC32, 0xF5F8, b"meta_pkg"),
        (0x23740, 0x2316C, b"ref_sort"),
        (0x6462A, 0x644B4, b"music_ir"),
    ]:
        offset = pe.get_offset_from_rva(site_rva)
        assert data[offset : offset + 5] == b"\xe8" + struct.pack("<i", original - site_rva - 5)
        data[offset : offset + 5] = b"\xe8" + struct.pack("<i", rva + hooks[hook] - site_rva - 5)
    site_rva = 0x231D2
    offset = pe.get_offset_from_rva(site_rva)
    assert data[offset : offset + 5] == bytes.fromhex("89 16 83 c6 04")
    data[offset : offset + 5] = b"\xe8" + struct.pack("<i", rva + hooks[b"ref_put"] - site_rva - 5)
    # This callback pointer already carries a HIGHLOW relocation in stock D7.
    callback = pe.get_offset_from_rva(0x29AF6)
    assert struct.unpack_from("<I", data, callback)[0] == 0x4299CC
    assert any(e.type == 3 and e.rva == 0x29AF6 for block in pe.DIRECTORY_ENTRY_BASERELOC for e in block.entries)
    struct.pack_into("<I", data, callback, 0x400000 + rva + hooks[b"rs_time"])
    data.extend(bytes(raw - len(data)))
    data.extend(code)
    data.extend(bytes(size - len(code)))
    output.write_bytes(data)
    shutil.copy2(source.parent / "rlink32.dll", output.parent / "rlink32.dll")
    print(
        f"Prepared {output}: {len(names)} units, {len(metadata)} startup/package entries, "
        f"{len(references)} reference cells, GetMusicFile IR initialization"
    )


if __name__ == "__main__":
    main()
