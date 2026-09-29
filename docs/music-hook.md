# Music compiler compatibility hook

This note covers Delphi 7 Enterprise **7.0.4.453**, with optimization enabled,
and the English Steam SR1 **1.7.2** target.

The prepared compiler initializes one otherwise uninitialized intermediate
representation (IR) field when compiling the final `TrimWideString` call in
`GR_Music.GetMusicFile`. This makes the recovered routine reproduce the native
400-byte body without depending on memory left by previously compiled routines.
The rule is implemented in [music_ir.s](../toolchain/delphi/music_ir.s) and
installed by [prepare.py](../toolchain/delphi/prepare.py). The project uses the
prepared compiler. Delphi emits the resulting instructions; the executable is
not post-processed.

## Native teardown

The native `GetMusicFile` occupies `$004BB43C` through `$004BB5CB`, inclusive:
**400 bytes**. Its selected-file path ends with:

```pascal
Result := TrimWideString(LowerCaseWideString(bp.GetParamValue(i)));
Exit;
```

`WideString` uses a hidden result pointer. The final `TrimWideString` writes
directly into the enclosing function's result storage. In the native code,
`$004BB56F` loads that destination into EDX and `$004BB572` calls
`TrimWideString`. The next instructions remove the inner exception frame:

```asm
; Game $004BB577: preserving form, 10 bytes
64 8F 05 00 00 00 00    pop dword ptr fs:[0]
83 C4 08                add esp, 8
```

With the recovered Pascal and an uninitialized call-result field, stock D7 can
instead emit:

```asm
; Compact form, 8 bytes
33 C0                   xor eax, eax
5A                      pop edx
59                      pop ecx
59                      pop ecx
64 89 10                mov fs:[eax], edx
```

Both remove three stack words and restore the preceding SEH-chain head. The
compact form also overwrites EAX, EDX and ECX. D7 selects it only when all three
registers are free. This two-byte difference gives a **398-byte** routine and
moves later instructions, relative branch/call displacements and one relocation
within the function's output.

## Allocation and the missing initialization

D7's transient allocator descends through reusable arena blocks, preserving
their previous contents. Each node constructor initializes its own fields.

| Compiler address | Operation relevant to the result byte |
| --- | --- |
| `$004270B4` | `acquire_arena_block`: reuse a suitable available block or obtain a virtual region, rounded to 64 KiB |
| `$004272D8` | `allocate_transient_record`: subtract the requested size from the transient cursor; return existing memory without zeroing it |
| `$00427318` | `reset_transient_pool`: return transient blocks to the arena allocator and reset the cursor |
| `$00417234` | `parse_call_expression`: construct a call node |
| `$004172AF`–`$004172B4` | Request **60 bytes** and call `allocate_transient_record` |
| `$004172BB`–`$004172D7` | Initialize the source line, auxiliary fields, kind `$A8`, flags `$0001`, callee and result type; omit byte `+$0C` |

The relevant call-node layout is:

| Offset | Field |
| --- | --- |
| `+$00` | Node kind; `$A8` denotes a call |
| `+$02` | Word flags; bit `$08` denotes an in-place result |
| `+$0C` | Byte result-location code, later used to index register dependencies |
| `+$10` | Result type descriptor pointer |
| `+$14` | Callee expression/symbol pointer |
| `+$18` | Argument-list pointer |
| `+$24` | Source line number |

The result-location code indexes the 125-entry array of 32-bit register-dependency
masks at `$0049F2A4`. A byte left by an earlier node can therefore select an
unrelated register location or index beyond the array.

## In-place result preparation

The assignment analysis calls `can_assign_result_in_place` at `$00431B8B`.
When it succeeds, `$00431BA0` sets flag `$08` on the call node and `$00431BA5`
sets it on the assignment. The call's flags become `$0009`; its location byte
is still untouched.

At `$00460815`, in-place assignment emission appends the actual destination as
the hidden result argument. It then calls `generate_call_expression`
(`$0046452C`). That function invokes `prepare_hidden_call_result` at
`$0046462A`; the original helper entry is `$004644B4`.

The helper distinguishes two paths:

```asm
; Compiler $004644BD
 test byte ptr [esi+2], 8
 jnz  $004644E8
 ; Ordinary result: rewrite the call as a stack temporary.
 mov  eax, esi
 call rewrite_node_as_stack_temporary  ; CALL at $004644C5
```

For an ordinary managed result, the stack-temporary rewrite assigns a valid
location. For an in-place result, the jump to `$004644E8` skips that rewrite.
The register-convention call already has its destination argument, so the helper
returns without assigning `call+$0C`. The preparation and liveness passes also
leave it untouched, so the uninitialized value survives through call emission.

## Register dependencies and teardown selection

After emitting the call, D7 releases the volatile registers and removes the
dependencies indexed by the result-location byte from the free mask:

```asm
; Compiler $004648E9–$00464902
 or   dword ptr [$004AE860], 7       ; EAX, EDX, ECX become free
 xor  edx, edx
 mov  dl, [ebx+$0C]                 ; $004648F2: uninitialized byte read
 mov  eax, [esp+$14]
 mov  ecx, [edx*4+$0049F2A4]        ; dependency table; no bounds check
 not  ecx
 and  dword ptr [$004AE860], ecx
```

`$004AE860` is `free_register_mask`. Its low three bits are EAX=`$01`,
EDX=`$02`, ECX=`$04`. After the call, managed-string assignment emission
releases its temporaries and executes `free_register_mask |= $03` at
`$00460AC3`. This frees EAX and EDX while retaining any ECX reservation.

`emit_exception_frame_removal` at `$0045C284` tests `(free_register_mask & 7)
== 7`. The equal branch at `$0045C291` emits the compact form. The other branch,
at `$0045C2B6`, emits the preserving form. Thus an ECX dependency in the stale
byte survives the assignment's final release and changes the following `Exit`.

| Result-location code | Dependency mask | Free mask after call release, starting at `$3F` | After assignment OR `$03` | Teardown |
| --- | --- | --- | --- | --- |
| `$00` | `$01` | `$3E` | `$3F` | Compact |
| `$1E` | `$40` | `$3F` | `$3F` | Compact |
| `$3C` | `$14` | `$2B` | `$2B` | Preserving |
| `$6A` | `$00` | `$3F` | `$3F` | Compact |
| **`$02`** | **`$04`** | **`$3B`** | **`$3B`** | **Preserving** |

The compiler uses `$6A` for a call with no register result. Initializing in-place
calls to that value would leave all three volatile registers free and produce
the shorter music routine. Code `$02` supplies the ECX dependency required for
the native teardown.

## Dependence on earlier routines

With the unmodified compiler, the final Trim call in a full build inherits `$1E`
from an address node created during `TMusicUnit.Create`.
`create_backend_address_node` writes this tag at `$0045DFBD`; reuse places it at
the call's `+$0C` field. Its dependency mask `$40` leaves ECX free, producing the
compact teardown. Incremental compilation can instead leave call tag `$A8`
from `TMusicControl.Create` at that address. The resulting out-of-table lookup
reads zero and also produces the compact teardown.

Equivalent source spellings can move the final call node onto a different old
field. For example, these spellings in `GetMusicFile` produce a matching full
build through a different stale value:

```pascal
t := t + ExtractDigitsToIntW(bp.GetParamName(i));
t := RandomIntRange(0, -1 + t);
// In the selection loop:
t := t - ExtractDigitsToIntW(bp.GetParamName(i));
if not (t < 0) then
  Continue;
Result := TrimWideString(LowerCaseWideString(bp.GetParamValue(i)));
Exit;
```

While compiling `TMusicUnit.Execute`'s `Chunk < 0` expression, `$0041EF10`
executes `mov [eax+$14], ebx`, storing an operand pointer. The final Trim call
reuses the pointer's low byte, `$3C`, as its result location. Its dependency mask
`$14` reserves ECX and ESI, selecting the preserving teardown.

Changing only `if Chunk < 0 then Break` to `if 0 > Chunk then Break` in the
earlier routine breaks this source-only match even under `-B`. The earlier
routine's machine code remains identical, but the stale byte becomes `$F8`.
Its out-of-table lookup reads zero and the music body becomes 398 bytes.

A full rebuild removes dependence on which DCUs happen to be cached, but cannot
remove dependence on the source's allocation history. The hook initializes the
location explicitly so that unrelated source changes cannot choose its value.

## Hook entry, guards and mutation

Preparation replaces the five-byte CALL at compiler **RVA `$0006462A`**
(VA `$0046462A`) with a CALL to `music_ir` in the appended `.lnkord` section.
Before replacement, it asserts that the instruction is the stock
`E8 85 FE FF FF`, targeting RVA `$000644B4`.

At the intercepted call, EAX is the call-node pointer, DL is the calling
convention, and ECX points to the argument-list slot. The wrapper saves EFLAGS
and all general registers with `pushfd`/`pushad`, obtains the compiler image base
relative to its own code, and requires every condition below:

| Guard | Required value |
| --- | --- |
| Calling convention | DL = 0, Delphi `register` |
| Call-node kind | Byte at `call+$00` = `$A8` |
| Call-node flags | Word at `call+$02` = **exactly** `$0009` |
| Call result type | Descriptor at `call+$10`: kind at `+$00` = 15 (`WideString`), size at `+$08` = 4 |
| Module | `current_module` at `$004A786C` is non-null; its symbol at `+$68` is named exactly `GR_Music` |
| Enclosing procedure | `current_procedure` at `$004A7864` is non-null; its symbol at `+$0C` is named exactly `GetMusicFile` |
| Enclosing result | Result symbol at `current_procedure+$14` is non-null; its type at `+$10` has kind 15 |
| Direct callee | Symbol at `call+$14` has kind 9, 10 or 11 and is named exactly `TrimWideString` |

The name helper reads NUL-terminated symbol names at symbol offset `+$20` and
compares case-sensitively, including the terminator. Direct-callee kinds 9–11
follow D7's own dispatch test: a full source build uses kind 10, while a callee
loaded from a DCU can have kind 9. The initial trimming used to compare candidate
filenames has flags `$0001` and therefore bypasses the hook.

When all guards pass, the sole compiler-state mutation is:

```asm
mov byte ptr [esi+$0C], 2
```

The store applies regardless of the byte's previous contents. On both paths,
`popad`/`popfd` restore registers and flags, and a tail jump enters the original
helper at `$004644B4`. Its return goes back to the original caller. D7 then emits
the routine using the initialized field.

The resulting dependency mask `$04` changes the free mask from `$3F` to `$3B`.
Managed assignment retains that mask, and the following `Exit` selects the
native preserving teardown. This gives the 400-byte body with the ordinary
Pascal implementation.

The rule applies to the final in-place Trim call in both source and DCU callee
representations. Its scope follows the recovered native constraint: ECX must
remain reserved at this teardown. The original stale value remains unknown.
