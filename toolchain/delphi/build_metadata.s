# Deterministic resource timestamp callback.
.intel_syntax noprefix
.code32
.text
.globl rs_time
# cdecl callback(handle, DOS timestamp out, size out): keep normal I/O/errors.
rs_time:
 push dword ptr [esp+12]
 push dword ptr [esp+12]
 push dword ptr [esp+12]
 dcc_call 0x299cc
 add esp,12
 test eax,eax
 jnz time_done
 mov edx,[esp+8]
 mov dword ptr [edx],0x344f5c8b
time_done:
 ret
