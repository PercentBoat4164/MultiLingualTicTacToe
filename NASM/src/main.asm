bits 64
%include "system.asm"
global SYSTEM_GLOBAL_ENTRY

section .data
    ; Used to store the current drawn board
    board: db 0x0A, "Tic-Tac-Toe", 0x0A, " _ │ _ │ _ ", 0x0A, "───┼───┼───", 0x0A, " _ │ _ │ _ ", 0x0A, "───┼───┼───", 0x0A, " _ │ _ │ _ ", 0x0A, 0x0A
    boardLen equ $ - board

    ; Used to generate the board
    align 16
    boardState: db "123456789-------"

    ; Printing templates
    promptTextTemplate: db "_: "
    promptTextTemplateLen equ $ - promptTextTemplate
    playerWinsTextTemplate: db "Game over. _ wins!", 0x0A
    playerWinsTextTemplateLen equ $ - playerWinsTextTemplate

    ; Used for tie detection
    turnsRemaining: db 0x09

    ; Used for player management
    playerSymbols: db "XO"
    currentPlayerSymbol: db "X"
    currentPlayer: db 0

section .bss
    ; Used for collecting input
    userInput: resb 2

    ; Used for dynamic dispatching
    detectWinState: resq 1
    clearBoard: resq 1

section .rodata
    ; Used for win detection
    align 16
    winStates: dw 0b000000111, 0b000111000, 0b111000000, 0b001001001, 0b010010010, 0b100100100, 0b100010001, 0b001010100

    ; Used to indicate where in the board values should be inserted
    boardIndices: db 0x0E, 0x14, 0x1A, 0x40, 0x46, 0x4C, 0x72, 0x78, 0x7E
    boardIndicesLen equ $ - boardIndices

    ; Printing constants
    startingTextConstant: db "You will be asked to enter a number 1-9. The number that you choose directly corresponds to the square that you go in as shown on the example board below. ‘X’ will go first. ‘O’ will go second. Each square can only be entered once. Put three of your piece in a row to win.", 0x0A
    startingTextConstantLen equ $ - startingTextConstant
    invalidInputTextConstant: db "That does not correspond to an available square. Please try again.", 0x0A
    invalidInputTextConstantLen equ $ - invalidInputTextConstant
    tieGameText: db "Game over. No winner.", 0x0A
    tieGameTextLen equ $ - tieGameText

section .text
    SYSTEM_GLOBAL_ENTRY:
        call setupDispatches
        lea rsi, [rel startingTextConstant]
        mov rdx, startingTextConstantLen
        call SystemPrint
        call printBoard
        call [rel clearBoard]
        _SYSTEM_GLOBAL_ENTRY_mainGameLoop:
            mov al, byte [rel currentPlayerSymbol]
            mov byte [rel promptTextTemplate], al
            _SYSTEM_GLOBAL_ENTRY_requestInputUntilValid:
                lea rsi, [rel promptTextTemplate]
                mov rdx, promptTextTemplateLen
                call SystemPrint
                call collectInputByte
                test al, al
                je _SYSTEM_GLOBAL_ENTRY_requestInputUntilValid_
                lea rsi, [rel invalidInputTextConstant]
                mov rdx, invalidInputTextConstantLen
                call SystemPrint
                jmp _SYSTEM_GLOBAL_ENTRY_requestInputUntilValid
            _SYSTEM_GLOBAL_ENTRY_requestInputUntilValid_:
            mov al, byte [rel currentPlayerSymbol]
            lea rbx, [rel boardState]
            add bl, byte [rel userInput]
            mov byte [rbx], al
            call printBoard
            call [rel detectWinState]
            test al, al
            jne _SYSTEM_GLOBAL_ENTRY_playerWon
            mov al, byte [rel turnsRemaining]
            dec al
            mov [rel turnsRemaining], al
            test al, al
            je _SYSTEM_GLOBAL_ENTRY_tieGame
            movzx rax, byte [rel currentPlayer]
            xor al, 1
            mov byte [rel currentPlayer], al
            lea rbx, [rel playerSymbols]
            mov al, byte [rbx + rax]
            mov byte [rel currentPlayerSymbol], al
            jmp _SYSTEM_GLOBAL_ENTRY_mainGameLoop
        _SYSTEM_GLOBAL_ENTRY_playerWon:
            mov al, byte [rel currentPlayerSymbol]
            lea rsi, [rel playerWinsTextTemplate]
            mov byte [rsi + 0xB], al
            mov rdx, playerWinsTextTemplateLen
            jmp _SYSTEM_GLOBAL_ENTRY_printAndExit
        _SYSTEM_GLOBAL_ENTRY_tieGame:
            lea rsi, [rel tieGameText]
            mov rdx, tieGameTextLen
        _SYSTEM_GLOBAL_ENTRY_printAndExit:
        call SystemPrint
        xor rax, rax
        call SystemExit

    setupDispatches:
        mov eax, 0
        cpuid
        test ebx, 1 << 26
        jnz _setupDispatches_SSE2
        _setupDispatches_NONE:
            mov rax, detectWinState_implementation
            mov [rel detectWinState], rax
            mov rax, clearBoard_implementation
            mov [rel clearBoard], rax
            ret
        _setupDispatches_SSE2:
            mov rax, detectWinState_implementation_SSE2
            mov [rel detectWinState], rax
            mov rax, clearBoard_implementation_SSE2
            mov [rel clearBoard], rax
            ret
        _setupDispatches_AVX2:
            mov rax, detectWinState_implementation_AVX2
            mov [rel detectWinState], rax
            mov rax, clearBoard_implementation_AVX2
            mov [rel clearBoard], rax
            ret

    detectWinState_implementation:
        cmp byte [rel currentPlayerSymbol], "X"
        mov rax, [rel boardState]
        mov rbx, qword [rel winStates]
        mov rdx, qword [rel winStates + 8]
        jne _detectWinState_implementation_X
            mov cl, 4
            jmp _detectWinState_implementation_postSetup
        _detectWinState_implementation_X:
            xor cl, cl
        _detectWinState_implementation_postSetup:
        shr rax, cl
        mov r8, 0x0101010101010101
        and rax, r8  ; The first bit of each byte in RAX is set iff the corresponding boardState is the current player symbol
        mov r8, (1<<(56-0)) + (1<<(57-8)) + (1<<(58-16)) + (1<<(59-24)) + (1<<(60-32)) + (1<<(61-40)) + (1<<(62-48)) + (1<<(63-56)) + (1<<(64-64))
        imul rax, r8
        shr rax, 56
        mov ah, byte [rel boardState + 8]
        shr ah, cl
        and ah, 1  ; AX is filled with a bitmask matching the winStates layout
        mov cx, ax
        shl eax, 16
        or eax, ecx
        mov ecx, eax
        shl rax, 32
        or rax, rcx
        mov rcx, rax  ; RAX and RCX are filled with 4 of the bitmasks generated above
        and rax, rbx
        and rcx, rdx
        xor rax, rbx
        xor rcx, rdx  ; If any word in RAX or RCX is equal to 0, then the player has won
        mov r8, 0x7FFF7FFF7FFF7FFF
        mov rbx, rax
        mov rdx, rcx
        and rax, r8
        and rcx, r8
        add rax, r8
        add rcx, r8
        or rax, rbx
        or rcx, rdx
        or rax, r8
        or rcx, r8
        not rax
        test rax, rax
        setnz al
        not rcx
        test rcx, rcx
        setnz cl
        or al, cl
        ret

    detectWinState_implementation_SSE2:
        cmp byte [rel currentPlayerSymbol], "X"
        movdqa xmm0, [rel boardState]
        movdqa xmm1, [rel winStates]
        je _detectWinState_implementation_SSE2_X
            psllq xmm0, 5
            jmp _detectWinState_implementation_SSE2_postSetup
        _detectWinState_implementation_SSE2_X:
            psllq xmm0, 3
        _detectWinState_implementation_SSE2_postSetup:
        pmovmskb eax, xmm0
        movq xmm0, rax
        pshuflw xmm0, xmm0, 0
        movlhps xmm0, xmm0
        pand xmm0, xmm1
        pcmpeqw xmm0, xmm1
        pmovmskb eax, xmm0
        test ax, ax
        setnz al
        ret

    detectWinState_implementation_AVX2:
        cmp byte [rel currentPlayerSymbol], "X"
        movdqa xmm0, [rel boardState]
        movdqa xmm1, [rel winStates]
        je _detectWinState_implementation_AVX2_X
            psllq xmm0, 5
            jmp _detectWinState_implementation_AVX2_postSetup
        _detectWinState_implementation_AVX2_X:
            psllq xmm0, 3
        _detectWinState_implementation_AVX2_postSetup:
        pmovmskb eax, xmm0
        vpbroadcastw xmm0, ax
        pand xmm0, xmm1
        pcmpeqw xmm0, xmm1
        pmovmskb eax, xmm0
        test ax, ax
        setnz al
        ret

    clearBoard_implementation:
        mov rax, "        "
        mov qword [rel boardState], rax
        mov qword [rel boardState + 8], rax
        ret

    clearBoard_implementation_SSE2:
        mov rax, "        "
        movq xmm0, rax
        movlhps xmm0, xmm0
        movdqa [rel boardState], xmm0
        ret

    clearBoard_implementation_AVX2:
        mov al, " "
        vpbroadcastb xmm0, al
        movdqa [rel boardState], xmm0
        ret

    printBoard:
        lea rax, [rel board]
        lea rbx, [rel boardState]
        lea rcx, [rel boardIndices]
        mov r8, boardIndicesLen
        _printBoard_update:
            dec r8
            mov dl, byte [rbx + r8]
            movzx r9, byte [rcx + r8]
            mov [rax + r9], dl
            jnz _printBoard_update
        lea rsi, [rel board]
        mov rdx, boardLen
        call SystemPrint
        ret

    collectInputByte:
        xor bl, bl
        lea rsi, [rel userInput]
        _collectInputByte_readUntilNewline:
            mov rdx, 2
            call SystemRead
            mov dx, word [rsi]
            cmp dl, 0x0A
            je _collectInputByte_readUntilNewline_
            cmp dh, 0x0A
            je _collectInputByte_readUntilNewline_
            mov bl, 1
            jmp _collectInputByte_readUntilNewline
        _collectInputByte_readUntilNewline_:
        cmp rax, 2
        mov rax, 1
        jne _collectInputByte_
        test bl, bl
        jne _collectInputByte_
        mov bl, byte [rsi]
        sub bl, '1'
        jl _collectInputByte_
        cmp bl, 8
        jg _collectInputByte_
        mov byte [rsi], bl
        lea rbx, [rel boardState]
        add bl, byte [rsi]
        movzx rbx, byte [rbx]
        cmp bl, ' '
        setne al
        _collectInputByte_:
        ret