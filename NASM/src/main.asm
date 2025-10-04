bits 64
%include "system.asm"
global SYSTEM_GLOBAL_ENTRY

section .data
    ; Used to store the current drawn board
    board: db 0x0A, "Tic-Tac-Toe", 0x0A, " _ │ _ │ _ ", 0x0A, "───┼───┼───", 0x0A, " _ │ _ │ _ ", 0x0A, "───┼───┼───", 0x0A, " _ │ _ │ _ ", 0x0A, 0x0A
    boardLen equ $ - board

    ; Used to generate the board
    align 16
    boardState: db "123456789       "
    boardIndices: db 0x0E, 0x14, 0x1A, 0x40, 0x46, 0x4C, 0x72, 0x78, 0x7E  ; Used to indicate where in the board values should be inserted
    boardIndicesLen equ $ - boardIndices

    ; Used for printing
    startingText: db "You will be asked to enter a number 1-9. The number that you choose directly corresponds to the square that you go in as shown on the example board below. ‘X’ will go first. ‘O’ will go second. Each square can only be entered once. Put three of your piece in a row to win.", 0x0A
    startingTextLen equ $ - startingText
    promptText: db "_: "
    promptTextLen equ $ - promptText
    invalidInputText: db "That does not correspond to an available square. Please try again.", 0x0A
    invalidInputTextLen equ $ - invalidInputText
    playerWinsText: db "Game over. _ wins!", 0x0A
    playerWinsTextLen equ $ - playerWinsText
    tieGameText: db "Game over. No winner.", 0x0A
    tieGameTextLen equ $ - tieGameText

    ; Used for player management
    playerSymbols: db "XO"
    currentPlayerSymbol: db "X"
    currentPlayer: db 0x00

    ; Used for win detection
    align 16
    winStates: dw 0b000000111, 0b000111000, 0b111000000, 0b001001001, 0b010010010, 0b100100100, 0b100010001, 0b001010100
    turnsRemaining: db 0x09

    ; Used for dynamic dispatching
    detectWinState: dd qword 0
    clearBoard: dd qword 0

section .bss
    ; Used for collecting input
    userInput: resb 0x2
    userInputLen equ $ - userInput

section .text
    ; The entry point; the meat of the program.
    SYSTEM_GLOBAL_ENTRY:
        call setupDispatches
        lea rax, [startingText]   ; rax = (char*)startingText;                                                           Get a pointer to the startingText
        mov rbx, startingTextLen  ; rbx = (uint64_t)startingTextLen;                                                     Load in the length of the startingText
        call SystemPrint          ; Print(startingText);                                                                 Print startingText(rax)
        call printBoard
        call [clearBoard]         ;                                                                                      Clear the board for future use
        _SYSTEM_GLOBAL_ENTRY_Loop1:  ; @Play for turnsRemaining in 9..0:
            _SYSTEM_GLOBAL_ENTRY_Loop2:  ; @Collect while userInput[0] is not valid:
                mov al, [currentPlayerSymbol]               ; al = (char)currentPlayerSymbol;                            Get the currentPlayerSymbol(al)
                mov [promptText], al  ; promptText[promptTextFillIndex] = al;                      Fill the promptText in with the currentPlayerSymbol(al)
                lea rax, [promptText]                       ; rax = (char*)promptText;                                   Get a pointer to the promptText
                mov rbx, promptTextLen                      ; rbx = (uint64_t)promptTextlen;                             Load in the length of the promptText
                call SystemPrint                            ; Print(promptText);                                         Print promptText(rax)
                call collectInputByte                       ; userInput = readLine(); al = isValid(userInput);           Get user's input and decide if it isValid(al)
                test al, al                                 ;                                                            Test if the input isValid(al)
                jne _SYSTEM_GLOBAL_ENTRY_Loop2END                          ; if isValid(userInput): break @Collect; else:               If so then leave the loop and compute the rest of this turn
                lea rax, [invalidInputText]                 ; rax = (char*)invalidInputText;                             If not then print the invalidInputText
                mov rbx, invalidInputTextLen                ; rbx = (uint64_t)invalidInputTextLen;                       Set up the print arguments
                call SystemPrint                            ; Print(invalidInputText);                                   Print the invalidInputText(rax)
                jmp _SYSTEM_GLOBAL_ENTRY_Loop2                             ; continue @Collect;                                         This input was invalid, so collect a new one
            _SYSTEM_GLOBAL_ENTRY_Loop2END:
            mov dl, [currentPlayerSymbol]                   ; ah = (char)currentPlayerSymbol;                            Get the currentPlayerSymbol(ah)
            lea rax, [boardState]
            add al, [userInput]
            mov byte [rax], dl
            call printBoard
            call [detectWinState]                           ; al = currentPlayerWon();                                   Check if the board isInWinState(al)
            test al, al                                     ;                                                            Test if the board isInWinState(al)
            jg _SYSTEM_GLOBAL_ENTRY_Loop1END                               ; if al: break @Play; else:                                  If so, end the game
            mov al, [turnsRemaining]                        ; al = (uint8_t)turnsRemaining;                              If not, get the number of remainingTurns(al)
            dec al                                          ; --al;                                                      One turn has been taken so decrease remainingTurns(al)
            mov [turnsRemaining], al                        ; turnsRemaining = al;                                       Set the number of remaining turns
            test al, al                                     ;                                                            Test if the number of remainingTurns(al) is zero
            je _SYSTEM_GLOBAL_ENTRY_Loop1END                               ; if !al: break @Play; else:                                 If so, there is was a tie, so end the game
            movzx rax, byte [currentPlayer]                 ; rax[al] = (uint8_t)currentPlayer;                          Get the currentPlayer(al)
            xor al, 0x01                                    ; al ^= 1;                                                   This player's turn was consumed, so switch to the other player
            mov [currentPlayer], al                         ; currentPlayer = al;                                        Set the currentPlayer
%ifdef MACOS
            lea rbx, [playerSymbols]                        ; rbx = (char*)playerSymbols;                                Get a pointer to the playerSymbols(rbx)
            mov al, [rax + rbx]                             ; al = (char)((char*)playerSymbols[(uint8_t)currentPlayer])  Get the playerSymbols(rbx) for the currentPlayer(al)
%else
            mov al, [rax + playerSymbols]                   ; al = (char)((char*)playerSymbols[(uint8_t)currentPlayer])  Get the symbol for the currentPlayer(al)
%endif
            mov [currentPlayerSymbol], al                   ; currentPlayerSymbol = al;                                  Set the currentPlayerSymbol(al)
            jmp _SYSTEM_GLOBAL_ENTRY_Loop1                                 ; continue @Play;                                            The game has not yet finished, so continue playing
        _SYSTEM_GLOBAL_ENTRY_Loop1END:
        test al, al                                         ;                                                            Check if the game ended in a tie
        je _SYSTEM_GLOBAL_ENTRY_ShowTieScreen                              ; if tied: showTieScreen(); else:                            If so, show the tie message
        mov al, [currentPlayerSymbol]                       ; rax[al] = (char)currentPlayerSymbol;                       If not, get the currentPlayerSymbol
        mov [playerWinsText + 0xB], al  ; playerWinsText[playerWinsTextFillIndex] = al;              Format the playerWinsText
        lea rax, [playerWinsText]                           ; rax = (char*)playerWinsText;                               Get a pointer to the newly formatted playerWinsText
        mov rbx, playerWinsTextLen                          ; rbx = (uint64_t)playerWinsTextLen;                         Load in the length of playerWinsText
        jmp _SYSTEM_GLOBAL_ENTRY_printAndReturn
        _SYSTEM_GLOBAL_ENTRY_ShowTieScreen:
        lea rax, [tieGameText]   ; rax = (char*)tieGameText;                                                             Get a pointer to the tieGameText
        mov rbx, tieGameTextLen  ; rbx = (uint64_t)tieGameTextLen;                                                       Load in the length of the tieGameText
        _SYSTEM_GLOBAL_ENTRY_printAndReturn:
        call SystemPrint  ; Print(playerWinsText or tieGameText);                                                        Print whichever message was loaded by the above code
        xor rax, rax      ; rax = 0;                                                                                     Set exit code zero
        call SystemExit   ; exit(0);                                                                                     Exit the program signaling success

    setupDispatches:
        push rax
        push rdx
        mov eax, 0
        cpuid
        test ebx, 1 << 26
        jnz _setupDispatches_SSE2
        _setupDispatches_NONE:
            mov rax, detectWinState_implementation
            mov [detectWinState], rax
            mov rax, clearBoard_implementation
            mov [clearBoard], rax
            jmp _setupDispatches
        _setupDispatches_SSE2:
            mov rax, detectWinState_implementation_SSE2
            mov [detectWinState], rax
            mov rax, clearBoard_implementation_SSE2
            mov [clearBoard], rax
            jmp _setupDispatches
        _setupDispatches_AVX2:
            mov rax, detectWinState_implementation_AVX2
            mov [detectWinState], rax
            mov rax, clearBoard_implementation_AVX2
            mov [clearBoard], rax
            jmp _setupDispatches
        _setupDispatches:
        pop rdx
        pop rax
        ret

    detectWinState_implementation:
        mov rax, [boardState]
        cmp byte [currentPlayerSymbol], "X"
        jne _detectWinState_implementation_X
            mov cl, 4
            jmp _detectWinState_implementation_postSetup
        _detectWinState_implementation_X:
            xor cl, cl
        _detectWinState_implementation_postSetup:
        shr rax, cl
        mov rdx, 0x0101010101010101
        and rax, rdx
        xor ch, ch
        or ch, al
        shr rax, 7
        or ch, al
        shr rax, 7
        or ch, al
        shr rax, 7
        or ch, al
        shr eax, 7
        or ch, al
        shr eax, 7
        or ch, al
        shr ax, 7
        or ch, al
        shr ax, 7
        or ch, al
        mov al, byte [boardState + 8]
        shr al, cl
        and al, 1
        mov cl, ch
        mov ch, al
        mov ax, cx
        and ax, 0b000000111
        xor ax, 0b000000111
        jz _detectWinState_implementation_playerWon
        mov ax, cx
        and ax, 0b000111000
        xor ax, 0b000111000
        jz _detectWinState_implementation_playerWon
        mov ax, cx
        and ax, 0b111000000
        xor ax, 0b111000000
        jz _detectWinState_implementation_playerWon
        mov ax, cx
        and ax, 0b001001001
        xor ax, 0b001001001
        jz _detectWinState_implementation_playerWon
        mov ax, cx
        and ax, 0b010010010
        xor ax, 0b010010010
        jz _detectWinState_implementation_playerWon
        mov ax, cx
        and ax, 0b100100100
        xor ax, 0b100100100
        jz _detectWinState_implementation_playerWon
        mov ax, cx
        and ax, 0b100010001
        xor ax, 0b100010001
        jz _detectWinState_implementation_playerWon
        mov ax, cx
        and ax, 0b001010100
        xor ax, 0b001010100
        jz _detectWinState_implementation_playerWon
            xor rax, rax
            ret
        _detectWinState_implementation_playerWon:
            mov rax, 1
            ret

    detectWinState_implementation_SSE2:
        cmp byte [currentPlayerSymbol], "X"
        movdqa xmm0, [boardState]
        movdqa xmm1, [winStates]
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
        cmp byte [currentPlayerSymbol], "X"
        movdqa xmm0, [boardState]
        movdqa xmm1, [winStates]
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
        mov qword [boardState], rax
        mov qword [boardState + 8], rax
        ret

    clearBoard_implementation_SSE2:
        mov rax, "        "
        movq xmm0, rax
        movlhps xmm0, xmm0
        movdqa [boardState], xmm0
        ret

    clearBoard_implementation_AVX2:
        mov al, " "
        vpbroadcastb xmm0, al
        movdqa [boardState], xmm0
        ret

    printBoard:
        push rax
        push rbx
        push rcx
        push rdx
        push r8
        push r9
        lea rax, [board]
        lea rbx, [boardState]
        lea rcx, [boardIndices]
        mov r8, boardIndicesLen
        _printBoard_update:
            dec r8
            mov dl, byte [rbx + r8]
            movzx r9, byte [rcx + r8]
            mov [rax + r9], dl
            jnz _printBoard_update
        mov rbx, boardLen  ; rbx = (uint64_t)boardLen;                                                            Load in the length of the board
        call SystemPrint   ; Print(board);                                                                        Print the board(rax)
        pop r9
        pop r8
        pop rdx
        pop rcx
        pop rbx
        pop rax
        ret

    ; Takes    : rax = (char*)buffer, (uint64_t)rbx = bufferLength
    ; Clobbers :
    ; Returns  : al = (bool)currentPlayerWon
    ;
    ; Collects bytes from input in groups of userInputLen. Stops when the last byte is a new line character. Verifies
    ;  input is correctly sized, within the required numeric range, and available on the board. Returns true if all of
    ;  the previous are true, otherwise returns false.
    collectInputByte:
        push rbx  ; rbx is (uint64_t)userInputLen
        push cx   ; cl is (bool)bufferOverrun, ch is unused
%ifndef MACOS
        mov rbx, userInputLen   ; rbx = (uint64_t)userInputLen;                                                Load in the length of the buffer
%endif
        xor cl, cl              ; cl = false;                                                                  Buffer has not been overrun
        _collectInputByte_while_lastReadByteNot0x0A:            ; @Read while lastReadByte != 0x0A:
            lea rax, [userInput]                                ; rax = (char*)userInput;                      Get a pointer to the buffer to read into
%ifdef MACOS
            mov rbx, userInputLen                               ; rbx = (uint64_t)userInputLen;                Load in the length of the buffer
%endif
            call SystemRead                                     ; rax = read(rax, rbx);                        bytesRead(rax) is set after attempting to read bufferBytes(rbx) bytes into buffer(rax)
%ifdef MACOS
            lea rbx, [userInput]                                ; rbx = (char*)userInput                       Get a pointer to the buffer
            cmp byte [rax + rbx - 1], 0x0A                      ;                                              Compare the last byte that was read into the buffer with the newline character
%else
            cmp byte [rax + userInput - 1], 0x0A                ;                                              Compare the last byte that was read into the buffer with the newline character
%endif
            je _collectInputByte_while_lastReadByteNot0x0A_END  ; if lastReadByte == '\n': break @Read; else:  If the last read byte is a newline character then the entire input has been buffered, so exit the loop
            mov cl, 1                                           ; cl = true;                                   The buffer has been overrun, so set bufferOverrun(cl) to true
            jmp _collectInputByte_while_lastReadByteNot0x0A     ; continue @Read;                              Read in the next bit of the buffer
        _collectInputByte_while_lastReadByteNot0x0A_END:
        test cl, cl                           ;                                                                Was the buffer overrun
        jne _collectInputByte_returns_false   ; if cl: return false; else:                                     If so, return false
        cmp rax, 2                            ;                                                                Was exactly 2 bytes read
        jne _collectInputByte_returns_false   ; if rax != 2: return false; else:                               If not, return false
        movzx rax, byte [userInput]           ; rax[al] = ((char*)userInput)[0];                               We only care about the first byte of input, not the newline character
        sub al, '1'                           ; al -= '1';                                                     Converts input(al) into the numeric value of input(al) - 1
        jl _collectInputByte_returns_false    ; if al < 0: return false; else:                                 If so, return false
        cmp al, 8                             ;                                                                Is input(al) greater than 8
        jg _collectInputByte_returns_false    ; if al > 8: return false; else:                                 If so return false
        mov [userInput], al                   ; *(char*)userInput = al;                                        Put the numeric value back into userInput for later use
        lea rax, [boardState]
        add al, [userInput]
        movzx rax, byte [rax]
        cmp al, ' '                           ;                                                                Compare the queried state(al) with the empty state
        jne _collectInputByte_returns_false   ; if al != ' ': return false; else:                              If state(al) is not the empty state, then early exit returning false
        mov rax, 1                            ; rax = true;                                                    All checks passed, so this function should return true
        jmp _collectInputByte_return
        _collectInputByte_returns_false:
        xor rax, rax                          ; rax = false;                                                   One of the above checks failed, the input is invalid, so this function should return false
        _collectInputByte_return:
        pop cx
        pop rbx
        ret