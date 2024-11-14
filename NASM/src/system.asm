%define SYSTEM_CALL_MACOS_EXIT 0x02000001
%define SYSTEM_CALL_MACOS_READ 0x02000003
%define SYSTEM_CALL_MACOS_WRITE 0x02000004

%define SYSTEM_CALL_LINUX_EXIT 0x3C
%define SYSTEM_CALL_LINUX_READ 0x0
%define SYSTEM_CALL_LINUX_WRITE 0x1

%ifdef MACOS
    %include "lib/macos.asm"
%elifdef LINUX
    %include "lib/linux.asm"
%elifdef WINDOWS
    %error "WINDOWS is not yet a supported platform."
%else
    %error "MACOS, LINUX, and WINDOWS are not defined. Unknown platform."
%endif
