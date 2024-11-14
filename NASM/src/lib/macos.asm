%ifndef _MACOS_ASM
    %define _MACOS_ASM
    default rel

    %define SYSTEM_GLOBAL_ENTRY start

    %define SYSTEM_CALL_EXIT SYSTEM_CALL_MACOS_EXIT
    %define SYSTEM_CALL_READ SYSTEM_CALL_MACOS_READ
    %define SYSTEM_CALL_WRITE SYSTEM_CALL_MACOS_WRITE

    SystemPrint:  ; rax = (const char*)stringToPrint; rbx = (const uint64_t)characterCount;
        push rsi  ; push all used registers to the stack
        push rdx
        push rdi
        mov rsi, rax  ; print rbx bytes at rax
        mov rdx, rbx
        mov rax, SYSTEM_CALL_WRITE
        mov rdi, 0x01  ; stdout
        syscall
        mov rax, rsi  ; recall all used registers
        mov rbx, rdx
        pop rdi
        pop rdx
        pop rsi
        ret

    SystemRead:  ; rax = (char*)buffer; rbx = (const uint64_t)characterCount; rcx = (const uint64_t)fileDescriptor
        push rcx
        lea rsi, [rax]  ; read into buffer
        mov rax, SYSTEM_CALL_READ  ; read syscall
        mov rdx, rbx  ; read rbx bytes
        xor rdi, rdi  ; read from stdin
        syscall
        pop rcx
        ret

    SystemExit:  ; rax = (uint8_t)exitCode;
        mov rdi, rax
        mov rax, SYSTEM_CALL_EXIT
        syscall
        ret
%endif