%ifdef MACOS
    %define SYSTEM_GLOBAL_ENTRY start
    %define SYSTEM_CALL_EXIT 0x02000001
    %define SYSTEM_CALL_READ 0x02000003
    %define SYSTEM_CALL_WRITE 0x02000004
%elifdef LINUX
    %define SYSTEM_GLOBAL_ENTRY _start
    %define SYSTEM_CALL_EXIT 0x3C
    %define SYSTEM_CALL_READ 0x0
    %define SYSTEM_CALL_WRITE 0x1
%elifdef WINDOWS
    %error "WINDOWS is not yet a supported platform."
%else
    %error "MACOS, LINUX, and WINDOWS are not defined. Unknown platform."
%endif

SystemPrint:  ; rsi = (const char*)stringToPrint; rdx = (const uint64_t)characterCount;
    mov rax, SYSTEM_CALL_WRITE
    mov rdi, 0x01  ; stdout
    syscall
    ret

SystemRead:  ; rsi = (char*)buffer; rdx = (const uint64_t)characterCount;
    mov rax, SYSTEM_CALL_READ  ; read syscall
    xor rdi, rdi  ; read from stdin
    syscall
    ret

SystemExit:  ; rax = (uint8_t)exitCode;
    mov rdi, rax
    mov rax, SYSTEM_CALL_EXIT
    syscall
    ret