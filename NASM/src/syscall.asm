%define SYSCALL_CODE_MACOS_EXIT 0x02000001
%define SYSCALL_CODE_MACOS_READ 0x02000003
%define SYSCALL_CODE_MACOS_WRITE 0x02000004

%define SYSCALL_CODE_LINUX_EXIT
%define SYSCALL_CODE_LINUX_READ
%define SYSCALL_CODE_LINUX_WRITE

%ifdef MACOS
    %define SYSCALL_CODE_EXIT SYSCALL_CODE_MACOS_EXIT
    %define SYSCALL_CODE_EXIT SYSCALL_CODE_MACOS_EXIT
    %define SYSCALL_CODE_EXIT SYSCALL_CODE_MACOS_EXIT

    print:  ; rax = (const char*)stringToPrint; rbx = (const uint64_t)characterCount;
        push rsi  ; push all used registers to the stack
        push rdx
        push rdi
        mov rsi, rax  ; print rbx bytes at rax
        mov rdx, rbx
        mov rax, SYSCALL_CODE_WRITE
        mov rdi, 0x01  ; stdout
        syscall
        mov rax, rsi  ; recall all used registers
        mov rbx, rdx
        pop rdi
        pop rdx
        pop rsi
        ret

    read:  ; rax = (char*)buffer; rdx = (const uint64_t)bufferLen
        mov rax, SYSCALL_CODE_READ  ; read syscall
        lea rsi, [rel scratchBuffer]  ; read into scratch buffer
        mov rdx, 0x01  ; read 1 byte
        xor rdi, rdi  ; read from stdin
        syscall

    exit:  ; rax = (byte)exitCode;
        mov rdi, rax
        mov rax, SYSCALL_CODE_EXIT
        syscall
        ret

%elifdef UNIX
%elifdef WINDOWS
%else
    %error "MACOS, UNIX, and WINDOWS are not defined. Unknown platform."
%endif
