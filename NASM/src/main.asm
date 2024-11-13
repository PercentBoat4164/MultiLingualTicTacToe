bits 64
global start

%include "syscall.asm"

section .data
    ; Used to store the current drawn board
    board: db 0x0A, "Tic-Tac-Toe", 0x0A, " 1 │ 2 │ 3 ", 0x0A, "───┼───┼───", 0x0A, " 4 │ 5 │ 6 ", 0x0A, "───┼───┼───", 0x0A, " 7 │ 8 │ 9 ", 0x0A, 0x0A
    boardLen equ $ - board

    ; Used to generate the board
    boardFillIndices: db 0x0E, 0x14, 0x1A, 0x40, 0x46, 0x4C, 0x72, 0x78, 0x7E  ; Used to indicate where in the boardTopTemplate values should be inserted
    boardState: db "123456789"  ; The current board's state
    boardStateLen equ $ - boardState

    ; Used for printing
    newLine: db 0x0A
    newLineLen equ $ - newLine
    startingText: db "You will be asked to enter a number 1-9. The number that you choose directly corresponds to the square that you go in as shown on the example board below. ‘X’ will go first. ‘O’ will go second. Each square can only be entered once. Put three of your piece in a row to win.", 0x0A
    startingTextLen equ $ - startingText
    playerSymbol: db "XO"
    playerSymbolLen equ $ - playerSymbol
    prompt: db "_: "
    promptLen equ $ - prompt
    invalidInputText: db "That does not correspond to an available square. Please try again.", 0x0A
    invalidInputTextLen equ $ - invalidInputText
    playerWinsText: db "Game over. _ wins!", 0x0A
    playerWinsTextLen equ $ - playerWinsText
    playerWinsTextFillIndex equ 0x0B
    tieGameText: db "Game over. No winner.", 0x0A
    tieGameTextLen equ $ - tieGameText

    ; Used for player management
    currentPlayer: db 0x00
    currentPlayerLen equ $ - currentPlayer

    ; Used for win detection
    winStates: db 0x00,0x01,0x02, 0x03,0x04,0x05, 0x06,0x07,0x08, 0x00,0x03,0x06, 0x01,0x04,0x07, 0x02,0x05,0x08, 0x00,0x04,0x08, 0x02,0x04,0x06
    winStatesLen equ $ - winStates
    winStateLen equ 0x03
    turnsBeforeGameEnd equ 0x09

section .bss
    ; Used for collecting input
    userInput: resb 0x1
    userInputLen equ $ - userInput
    scratchBuffer: resb 0x01
    scratchBufferLen equ $ - scratchBuffer

section .text
    start:  ; Initial conditions for the start of the game
        lea rax, [rel startingText]  ; Print starting text
        mov rbx, startingTextLen
        call printString
        lea rax, [rel board]  ; Print the numbered board
        mov rbx, boardLen
        call printString
        call clearBoard  ; Clear the board for future use
        _startLoop1:  ; Start of the main game loop
            _startLoop2:
                call generatePrompt
                lea rax, [rel prompt]  ; Give prompt
                mov rbx, promptLen
                call printString
                call collectInputByte  ; Get user decision
                call verifyValidInput  ; Ensure that user input is valid, and re-request it if it is not.
                cmp rax, 0x00
                jg _startLoop2END  ; Input is valid so leave this loop
                lea rax, [rel invalidInputText]  ; Input is invalid so request new input
                mov rbx, invalidInputTextLen
                call printString
                jmp _startLoop2
            _startLoop2END:
                call generateBoardState  ; Regenerate and redraw the board
                call generateBoard
                lea rax, [rel board]
                mov rbx, boardLen
                call printString
                call detectWinState
                cmp rax, 0x00
                jg _startLoop1END  ; End the game if a player won
                call detectTieState
                xor rax, 0x01  ; Invert the results of the tie state detection
                cmp rax, 0x00
                je _startLoop1END  ; End the game if there is a tie
                call switchCurrentPlayer
                jmp _startLoop1
        _startLoop1END:
            cmp rax, 0x00
            je _startShowTieScreen
            call generatePlayerWinsText
            lea rax, [rel playerWinsText]
            mov rbx, playerWinsTextLen
            jmp _startReturn
        _startShowTieScreen:
            lea rax, [rel tieGameText]
            mov rbx, tieGameTextLen
        _startReturn:
            call printString
        call exit
        ret

    generatePlayerWinsText:
        push rax
        push rbx
        xor rax, rax
        mov al, [rel currentPlayer]
        lea rbx, [rel playerSymbol]
        mov al, byte [rax + rbx]
        mov byte [rel playerWinsText + playerWinsTextFillIndex], al
        pop rbx
        pop rax
        ret

    detectTieState:
        push rcx
        xor rcx, rcx
        xor rax, rax
        _detectTieStateLoop1:
            lea rax, [rel boardState]
            cmp byte [rcx + rax], " "  ; Check if any board value is " "
            je _detectTieStateReturnFalse
            inc rcx
            cmp rcx, boardStateLen
            jl _detectTieStateLoop1
        mov rax, 0x01
        _detectTieStateReturnFalse:
            pop rcx
        ret

    detectWinState:  ; rax = 1 if the current player has won, else rax = 0
        push rbx
        push rcx
        push rdx
        push r8
        movzx rbx, byte [rel currentPlayer]
        lea rax, [rel playerSymbol]
        mov bl, [rbx + rax]  ; bl is used to store the current player's symbol
        xor rcx, rcx  ; rcx is used to iterate over winStates
        _detectWinStateLoop1:
            xor rax, rax  ; rax is used to determine how deep into the current state we are looking
            _detectWinStateLoop2:
                lea rdx, [rcx * winStateLen]  ; Address(rdx) = currentState(rcx) * winStateLen + currentStateOffset(rax) + winStates
                add rdx, rax
                lea r8, [rel winStates]
                add rdx, r8
                movzx rdx, byte [rdx]
                lea r8, [rel boardState]
                add rdx, r8
                mov bh, [rdx]  ; bh is used to store the boardState for the area under consideration
                cmp bl, bh
                jne _detectWinStateLoop2END
                    inc rax  ; Could be this state. Track how many times it could be this state
                    cmp rax, winStateLen
                    jl _detectWinStateLoop2
                        mov rax, 0x01
                        jmp _detectWinStateLoop1END
            _detectWinStateLoop2END:
            inc rcx
            cmp rcx, winStatesLen / winStateLen
            jl _detectWinStateLoop1
            mov rax, 0x00
        _detectWinStateLoop1END:
        pop r8
        pop rdx
        pop rcx
        pop rbx
        ret

    clearBoard:  ; Fill boardState with " "s
        push rax
        push rcx
        lea rax, [rel boardState]
        xor rcx, rcx
        _clearBoardLoop1:
            mov byte [rcx + rax], ' '  ; Set each value in boardState to ' '
            inc rcx
            cmp rcx, boardStateLen
            jl _clearBoardLoop1
        pop rcx
        pop rax
        ret

    generateBoard:  ; Takes no arguments. Changes data at 'board' to have the contents of the current board state.
        push rcx
        push rbx
        push rax
        push rdx
        xor rcx, rcx
        _generateBoardLoop1:  ; For every template index, copy boardState[rcx] into board[template_index]
            lea rdx, [rel boardFillIndices]
            movzx rax, byte [rcx + rdx]
            lea rdx, [rel boardState]
            mov bl, [rcx + rdx]
            lea rdx, [rel board]
            mov byte [rax + rdx], bl
            inc rcx
            cmp rcx, boardStateLen
            jl _generateBoardLoop1
        pop rdx
        pop rax
        pop rbx
        pop rcx
        ret

    generateBoardState:
        push rax
        push rbx
        push rcx
        movzx rax, byte [rel currentPlayer]
        lea rcx, [rel playerSymbol]
        mov al, [rax + rcx]
        movzx rbx, byte [rel userInput]
        lea rcx, [rel boardState]
        mov byte [rbx + rcx], al
        pop rcx
        pop rbx
        pop rax
        ret

    switchCurrentPlayer:  ; Change current player to 0 or 1 if 1 or 0 respectively
        push rax
        mov al, [rel currentPlayer]
        xor al, 0x01
        mov byte [rel currentPlayer], al
        pop rax
        ret

    generatePrompt:  ; Given the currentPlayer, apply the appropriate playerSymbol to the prompt
        push rax
        push rbx
        lea rax, [rel playerSymbol]
        mov bl, [rel currentPlayer]
        mov al, [rax + rbx]
        mov byte [rel prompt], al
        pop rbx
        pop rax
        ret

    verifyValidInput:  ; rax = 1 if input is valid, rax = 0 otherwise
        push rbx
        movzx rax, byte [rel userInput]
        sub al, '1'  ; converts ASCII character into numeric_value - 1
        mov byte [rel userInput], al
        cmp al, 0x00  ; userInput[0] >= 1
        jl _verifyValidInputReturnsFalse
        cmp al, 0x08  ; userInput[0] <= 9
        jg _verifyValidInputReturnsFalse
        lea rbx, [rel boardState]
        mov al, [rax + rbx]
        cmp al, " "  ; boardState[userInput] != " "
        jne _verifyValidInputReturnsFalse
        mov rax, 0x01
        pop rbx
        ret
        _verifyValidInputReturnsFalse:
            xor rax, rax
            pop rbx
            ret

    collectInputByte:  ; read 1 byte into userInput, rejecting strings longer or shorter than one byte
        push rax
        push rdi
        push rsi
        push rdx
        push rbx
        push rcx
        lea rsi, [rel userInput]  ; read stdin syscall
        mov rdx, 0x01
        mov rax, SYSCALL_CODE_READ
        xor rdi, rdi
        syscall
        mov bl, [rel userInput]  ; bl is used to compare inputs to expected values
        cmp bl, 0x0A  ; If the first character was an enter press, reject it.
        je _collectInputByteReturnNone
        xor rcx, rcx  ; rcx will be used for counting the number of chars skipped
        _collectInputByteLoop1:
            push rcx
            mov rax, SYSCALL_CODE_READ  ; read syscall
            lea rsi, [rel scratchBuffer]  ; read into scratch buffer
            mov rdx, 0x01  ; read 1 byte
            xor rdi, rdi  ; read from stdin
            syscall
            pop rcx
            inc rcx
            mov bl, [rel scratchBuffer]
            cmp bl, 0x0A  ; Look at a new char in the input buffer
            jne _collectInputByteLoop1  ; Loop until the enter button is found
        _collectInputByteReturnNone:
            cmp rcx, 0x01  ; Only keep the byte if the first character was not 0x0A
            je _collectInputByteReturnByte
            mov byte [rel userInput], 0x00
        _collectInputByteReturnByte:
            mov al, [rel userInput]
        pop rcx
        pop rbx
        pop rdx
        pop rsi
        pop rdi
        pop rax
        ret

    printString:  ; print rbx bytes at rax
        push rsi  ; push all used registers to the stack
        push rdx
        push rdi
        mov rsi, rax  ; print rbx bytes at rax
        mov rdx, rbx
        mov rax, SYSCALL_CODE_WRITE
        mov rdi, 0x01
        syscall
        mov rax, rsi  ; recall all used registers
        mov rbx, rdx
        pop rdi
        pop rdx
        pop rsi
        ret

    exit:
        mov rax, SYSCALL_CODE_EXIT
        xor rdi, rdi
        syscall
        ret