bits 64
%include "system.asm"
global SYSTEM_GLOBAL_ENTRY

section .data
    ; Used to store the current drawn board
    board: db 0x0A, "Tic-Tac-Toe", 0x0A, " 1 │ 2 │ 3 ", 0x0A, "───┼───┼───", 0x0A, " 4 │ 5 │ 6 ", 0x0A, "───┼───┼───", 0x0A, " 7 │ 8 │ 9 ", 0x0A, 0x0A
    boardLen equ $ - board

    ; Used to generate the board
    align 16
    boardState: db "         "

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
        lea rsi, [rel startingTextConstant]
        mov rdx, startingTextConstantLen
        call SystemPrint
        lea rsi, [rel board]
        mov rdx, boardLen
        call SystemPrint
        lea rax, [rel board]
        lea rbx, [rel boardIndices]
        mov rcx, boardIndicesLen
        ClearBoardLoop:
            dec rcx
            movzx rdx, byte [rbx + rcx]
            mov byte [rax + rdx], ' '
            jnz ClearBoardLoop
        MainGameLoop:
            mov al, byte [rel currentPlayerSymbol]
            mov byte [rel promptTextTemplate], al
            RequestInputUntilValid:
                xor rbx, rbx
                lea rsi, [rel promptTextTemplate]
                mov rdx, promptTextTemplateLen
                call SystemPrint
                lea rsi, [rel userInput]
                InputLoop:
                    mov rdx, 2
                    call SystemRead
                    movzx rax, word [rsi]
                    inc rbx
                    sub ah, 0x0A
                    jnz InputLoop
                cmp rbx, 1
                jne InputIsInvalid
                sub al, '1'
                jl InputIsInvalid
                cmp al, 8
                jg InputIsInvalid
                mov byte [rsi], al
                lea rbx, [rel boardState]
                mov al, byte [rbx + rax]
                cmp al, ' '
                jne InputIsInvalid
            mov al, byte [rel currentPlayerSymbol]
            lea rbx, [rel boardState]
            movzx rcx, byte [rel userInput]
            lea rdx, [rel boardIndices]
            lea rsi, [rel board]
            mov byte [rbx + rcx], al
            movzx rbx, byte [rdx + rcx]
            mov byte [rbx + rsi], al
            mov rdx, boardLen
            call SystemPrint
            cmp al, "X"
            movdqa xmm0, [rel boardState]
            mov eax, 5
            mov ecx, 3
            cmovne eax, ecx
            movd xmm1, eax
            psllq xmm0, xmm1
            movdqa xmm1, [rel winStates]
            pmovmskb eax, xmm0
            movq xmm0, rax
            pshuflw xmm0, xmm0, 0
            movlhps xmm0, xmm0
            pand xmm0, xmm1
            pcmpeqw xmm0, xmm1
            pmovmskb eax, xmm0
            test ax, ax
            jne PlayerWon
            dec byte [rel turnsRemaining]
            jz TieGame
            xor byte [rel currentPlayer], 1
            setnz al
            lea rbx, [rel playerSymbols]
            mov al, byte [rbx + rax]
            mov byte [rel currentPlayerSymbol], al
            jmp MainGameLoop
        PlayerWon:
            mov al, byte [rel currentPlayerSymbol]
            lea rsi, [rel playerWinsTextTemplate]
            mov byte [rsi + 0xB], al
            mov rdx, playerWinsTextTemplateLen
            jmp Exit
        TieGame:
            lea rsi, [rel tieGameText]
            mov rdx, tieGameTextLen
    Exit:
        call SystemPrint
        xor rdi, rdi
        call SystemExit

    InputIsInvalid:
        lea rsi, [rel invalidInputTextConstant]
        mov rdx, invalidInputTextConstantLen
        call SystemPrint
        jmp RequestInputUntilValid