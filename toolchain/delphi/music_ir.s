# D7 7.0.4.453 compatibility for one proven uninitialized call-result field.
# Only IRNode.register_code is written. All instructions are emitted by D7.
.intel_syntax noprefix
.code32
.text
.globl music_ir

# Wrap only the managed-result preparation CALL at compiler RVA 0x6462a.
# EAX = call node, DL = calling convention, ECX = argument-list address.
music_ir:
 pushfd
 pushad
 mov esi,eax
 test dl,dl                       # register convention only
 jnz music_original
 cmp byte ptr [esi],0xa8          # NODE_CALL
 jne music_original
 cmp word ptr [esi+2],9           # ordinary node + in-place result
 jne music_original
 mov eax,[esi+16]
 cmp byte ptr [eax],15            # TYPE_WIDESTRING
 jne music_original
 cmp dword ptr [eax+8],4
 jne music_original
 call music_base
music_base:
 pop ebp
 .equ music_base_rva,HOOK_RVA+music_base-start
 sub ebp,offset music_base_rva

 mov eax,[ebp+0xa786c]            # current_module
 test eax,eax
 jz music_original
 mov eax,[eax+0x68]               # module symbol
 .equ music_unit_rva,HOOK_RVA+music_unit-start
 lea edi,[ebp+music_unit_rva]
 call music_name
 test eax,eax
 jz music_original

 mov ebx,[ebp+0xa7864]            # current_procedure
 test ebx,ebx
 jz music_original
 mov eax,[ebx+12]                 # procedure symbol
 .equ music_proc_rva,HOOK_RVA+music_proc-start
 lea edi,[ebp+music_proc_rva]
 call music_name
 test eax,eax
 jz music_original
 mov eax,[ebx+20]                 # enclosing function's result symbol
 test eax,eax
 jz music_original
 mov eax,[eax+16]
 cmp byte ptr [eax],15
 jne music_original

 mov eax,[esi+20]                 # direct callee symbol
 mov dl,[eax]
 sub dl,9
 cmp dl,2                        # direct procedure kinds 9..11, as in D7
 ja music_original               # excludes dispatched/indirect calls
 .equ music_trim_rva,HOOK_RVA+music_trim-start
 lea edi,[ebp+music_trim_rva]
 call music_name
 test eax,eax
 jz music_original

 # The original teardown requires ECX reserved after EAX/EDX are released.
 # Code 2 is the minimal valid location with that dependency. The original
 # stale byte is unknowable and changes between -B and -M; do not condition
 # initialization on its previous contents. Supply only its required effect.
 mov byte ptr [esi+12],2
music_original:
 popad
 popfd
 .byte 0xe9
 .long 0x644b4-(HOOK_RVA+(. - start)+4)

# Exact, case-sensitive symbol name including terminator. No prefix matches.
music_name:
 test eax,eax
 jz music_name_end
 add eax,32
music_name_next:
 mov dl,[eax]
 cmp dl,[edi]
 jne music_name_bad
 test dl,dl
 jz music_name_good
 inc eax
 inc edi
 jmp music_name_next
music_name_bad:
 xor eax,eax
 ret
music_name_good:
 mov eax,1
music_name_end:
 ret

music_unit: .asciz "GR_Music"
music_proc: .asciz "GetMusicFile"
music_trim: .asciz "TrimWideString"
