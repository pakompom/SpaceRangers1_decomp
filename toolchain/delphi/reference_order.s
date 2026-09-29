# D7 reference buckets stay intact; assign an explicit permutation of the same targets.
.intel_syntax noprefix
.code32
.text
.globl ref_sort, ref_put
ref_sort:
 pushad
 call ref_base
ref_base:
 pop ebx
 .equ ref_rva,HOOK_RVA+ref_base-start
 sub ebx,offset ref_rva
 cmp dword ptr [ebx+0xa6164],REF_COUNT
 jne ref_fallback
 mov esi,[ebx+0xa6160]
 .equ keys_rva,HOOK_RVA+ref_keys-start
 lea ebx,[ebx+keys_rva]
 mov ebp,256
ref_next_bucket:
 mov edi,[esi]
ref_next_node:
 test edi,edi
 jz ref_advance_bucket
 mov eax,[edi+24]
 mov eax,[eax+20]
 xor ecx,ecx
ref_search_target:
 mov edx,[ebx+ecx*4]
 test edx,edx
 jz ref_fallback
 cmp eax,edx
 je ref_assign_slot
 inc ecx
 jmp ref_search_target
ref_assign_slot:
 mov edx,[esp+28]
 lea edx,[edx+ecx*4]
 mov [edi+20],edx
 mov edi,[edi+28]
 jmp ref_next_node
ref_advance_bucket:
 add esi,4
 dec ebp
 jnz ref_next_bucket
 add dword ptr [esp+28],REF_BYTES
 popad
 ret
ref_fallback:
 popad
 .byte 0xe9
 .long 0x2316c-(HOOK_RVA+(. - start)+4)
ref_put:
 push eax
 mov eax,[ebx+20]
 sub eax,edi
 mov [esi+eax],edx
 pop eax
 add esi,4
 ret
ref_keys:
