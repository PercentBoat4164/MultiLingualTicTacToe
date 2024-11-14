bits 64
%include "system.asm"
global SYSTEM_GLOBAL_ENTRY

section .data
   ; Used to store the current drawn board
    board: db 0x0A, "Tic-Tac-Toe", 0x0A, " 1 │ 2 │ 3 ", 0x0A, "───┼───┼───", 0x0A, " 4 │ 5 │ 6 ", 0x0A, "───┼───┼───", 0x0A, " 7 │ 8 │ 9 ", 0x0A, 0x0A
    boardLen equ $ - board

    ; Used to generate the board
    boardIndices: db 0x0E, 0x14, 0x1A, 0x40, 0x46, 0x4C, 0x72, 0x78, 0x7E  ; Used to indicate where in the board values should be inserted
    boardIndicesLen equ $ - boardIndices

    ; Used for printing
    startingText: db "You will be asked to enter a number 1-9. The number that you choose directly corresponds to the square that you go in as shown on the example board below. ‘X’ will go first. ‘O’ will go second. Each square can only be entered once. Put three of your piece in a row to win.", 0x0A
    startingTextLen equ $ - startingText
    promptText: db "_: "
    promptTextLen equ $ - promptText
    promptTextFillIndex equ 0x0
    invalidInputText: db "That does not correspond to an available square. Please try again.", 0x0A
    invalidInputTextLen equ $ - invalidInputText
    playerWinsText: db "Game over. _ wins!", 0x0A
    playerWinsTextLen equ $ - playerWinsText
    playerWinsTextFillIndex equ 0x0B
    tieGameText: db "Game over. No winner.", 0x0A
    tieGameTextLen equ $ - tieGameText

    ; Used for player management
    playerSymbols: db "XO"
    playerSymbolsLen equ $ - playerSymbols
    currentPlayerSymbol: db "X"
    currentPlayer: db 0x00

    ; Used for win detection
    ; winStates is a 2D array of indices into board. Each sub array holds 3 indices into board whose pointed-to values,
    ;  if all equal to the currentPlayerSymbol, means that the currentPlayer has won. There are 4 elements in each
    ;  subarray to facilitate effective addressing.
    winStates: dd 0x001A140E, 0x004C4640, 0x007E7872, 0x0072400E, 0x00784614, 0x007E4C1A, 0x007E460E, 0x0072461A
    winStatesLen equ $ - winStates
    winStateLenRelevant equ 0x03
    winStateLenPadded equ 0x04
    turnsRemaining: db 0x09

section .bss
    ; Used for collecting input
    userInput: resb 0x2
    userInputLen equ $ - userInput

section .text
    ; Takes    :
    ; Clobbers :
    ; Returns  :
    ;
    ; The entry point; the meat of the program.
    SYSTEM_GLOBAL_ENTRY:
        lea rax, [startingText]   ; rax = (char*)startingText;                                                           Get a pointer to the startingText
        mov rbx, startingTextLen  ; rbx = (uint64_t)startingTextLen;                                                     Load in the length of the startingText
        call SystemPrint          ; Print(startingText);                                                                 Print startingText(rax)
        lea rax, [board]          ; rax = (char*)board;                                                                  Get a pointer to the board
        mov rbx, boardLen         ; rbx = (uint64_t)boardLen;                                                            Load in the length of the board
        call SystemPrint          ; Print(board);                                                                        Print the board(rax)
        call clearBoard           ;                                                                                      Clear the board for future use
        _startLoop1:  ; @Play for turnsRemaining in 9..0:
            _startLoop2:  ; @Collect while userInput[0] is not valid:
                mov al, [currentPlayerSymbol]               ; al = (char)currentPlayerSymbol;                            Get the currentPlayerSymbol(al)
                mov [promptText + promptTextFillIndex], al  ; promptText[promptTextFillIndex] = al;                      Fill the promptText in with the currentPlayerSymbol(al)
                lea rax, [promptText]                       ; rax = (char*)promptText;                                   Get a pointer to the promptText
                mov rbx, promptTextLen                      ; rbx = (uint64_t)promptTextlen;                             Load in the length of the promptText
                call SystemPrint                            ; Print(promptText);                                         Print promptText(rax)
                call collectInputByte                       ; userInput = readLine(); al = isValid(userInput);           Get user's input and decide if it isValid(al)
                test al, al                                 ;                                                            Test if the input isValid(al)
                jne _startLoop2END                          ; if isValid(userInput): break @Collect; else:               If so then leave the loop and compute the rest of this turn
                lea rax, [invalidInputText]                 ; rax = (char*)invalidInputText;                             If not then print the invalidInputText
                mov rbx, invalidInputTextLen                ; rbx = (uint64_t)invalidInputTextLen;                       Set up the print arguments
                call SystemPrint                            ; Print(invalidInputText);                                   Print the invalidInputText(rax)
                jmp _startLoop2                             ; continue @Collect;                                         This input was invalid, so collect a new one
            _startLoop2END:
            mov ah, [currentPlayerSymbol]                   ; ah = (char)currentPlayerSymbol;                            Get the currentPlayerSymbol(ah)
            mov al, [userInput]                             ; al = ((char*)userInput)[0];                                Get the firstUserInputByte(al)
            call setBoardLocationState                      ; setBoardState(al, ah);                                     Set the board state at the userInput(al) to the currentPlayerSymbol(ah)
            lea rax, [board]                                ; rax = (char*)board;                                        Get a pointer to the board
            mov rbx, boardLen                               ; rbx = (uint64_t)boardLen;                                  Load in the length of the board
            call SystemPrint                                ; Print(board);                                              Print board(rax)
            call detectWinState                             ; al = currentPlayerWon();                                   Check if the board isInWinState(al)
            test al, al                                     ;                                                            Test if the board isInWinState(al)
            jg _startLoop1END                               ; if al: break @Play; else:                                  If so, end the game
            mov al, [turnsRemaining]                        ; al = (uint8_t)turnsRemaining;                              If not, get the number of remainingTurns(al)
            dec al                                          ; --al;                                                      One turn has been taken so decrease remainingTurns(al)
            mov [turnsRemaining], al                        ; turnsRemaining = al;                                       Set the number of remaining turns
            test al, al                                     ;                                                            Test if the number of remainingTurns(al) is zero
            je _startLoop1END                               ; if !al: break @Play; else:                                 If so, there is was a tie, so end the game
            movzx rax, byte [currentPlayer]                 ; rax[al] = (uint8_t)currentPlayer;                          Get the currentPlayer(al)
            xor al, 0x01                                    ; al ^= 1;                                                   This player's turn was consumed, so switch to the other player
            mov [currentPlayer], al                         ; currentPlayer = al;                                        Set the currentPlayer
            mov al, [rax + playerSymbols]                   ; al = (char)((char*)playerSymbols[(uint8_t)currentPlayer])  Get the symbol for the currentPlayer(al)
            mov [currentPlayerSymbol], al                   ; currentPlayerSymbol = al;                                  Set the currentPlayerSymbol(al)
            jmp _startLoop1                                 ; continue @Play;                                            The game has not yet finished, so continue playing
        _startLoop1END:
        test al, al                                         ;                                                            Check if the game ended in a tie
        je _startShowTieScreen                              ; if tied: showTieScreen(); else:                            If so, show the tie message
        mov al, [currentPlayerSymbol]                       ; rax[al] = (char)currentPlayerSymbol;                       If not, get the currentPlayerSymbol
        mov [playerWinsText + playerWinsTextFillIndex], al  ; playerWinsText[playerWinsTextFillIndex] = al;              Format the playerWinsText
        lea rax, [playerWinsText]                           ; rax = (char*)playerWinsText;                               Get a pointer to the newly formatted playerWinsText
        mov rbx, playerWinsTextLen                          ; rbx = (uint64_t)playerWinsTextLen;                         Load in the length of playerWinsText
        jmp _start_printAndReturn
        _startShowTieScreen:
        lea rax, [tieGameText]   ; rax = (char*)tieGameText;                                                             Get a pointer to the tieGameText
        mov rbx, tieGameTextLen  ; rbx = (uint64_t)tieGameTextLen;                                                       Load in the length of the tieGameText
        _start_printAndReturn:
        call SystemPrint  ; Print(playerWinsText or tieGameText);                                                        Print whichever message was loaded by the above code
        xor rax, rax      ; rax = 0;                                                                                     Set exit code zero
        call SystemExit   ; exit(0);                                                                                     Exit the program signaling success

    ; Takes    : al = (uint8_t)boardLocationIndex
    ; Clobbers : rax
    ; Returns  : al = (char)state
    ;
    ; Takes the index of a location on the board [0, 8] and returns the current state of the board at that location ['X', 'O', ' '].
    getBoardLocationState:
        movzx rax, byte [rax + boardIndices]  ; rax[al] = index;         Get the board string index of the given board location
        movzx rax, byte [rax + board]         ; rax[al] = board[index];  Get the board string value at that index
        ret

    ; Takes    : al = (uint8_t)boardLocationIndex, ah = (char)state
    ; Clobbers :
    ; Returns  :
    ;
    ; Takes the index of a location on the board [0, 8] and returns the current state of the board at that location ['X', 'O', ' '].
    setBoardLocationState:
        push rbx  ; bl is (uint8_t)boardLocationIndex
        movzx rbx, al                 ; rbx(bl) = al;  Move the location(al) for later use
        mov bl, [rbx + boardIndices]  ; bl = index;    Get the index(bl) corresponding to location(rbx)
        mov [rbx + board], ah         ; *index = ah;   Set the board's value at that index to the provided state(ah)
        pop rbx
        ret

    ; Takes    :
    ; Clobbers : rax
    ; Returns  : al = (bool)currentPlayerWon
    ; @todo This function could maybe(?) benefit from SIMD - A fun exercise and learning opportunity
    ; Returns true if the currentPlayer's pieces form a pattern that wins the game
    detectWinState:
        push rbx  ; bl is (char)currentPlayerSymbol, bh is (char)thisBoardState
        push rcx
        push rdx
        mov bl, [currentPlayerSymbol]  ; al = (char)currentPlayerSymbol;
        xor rcx, rcx                   ; rcx = 0;                                                                                   rcx is used to iterate over winStates
        _detectWinState_foreach_winState_winStates:  ; @WinStates for rcx in 0..winStatesLen:
            xor rax, rax                             ; rax = 0;                                                                     al is used to iterate over each winState and is used as the return value
            _detectWinState_foreach_boardIndex_winState:  ; @WinState for rax in 0..3:
                    ; boardIndex(rdx) = winStateIndex(al) + currentWinState(rcx) * winStateLen(actually 4 instead of 3) + winStates
                movzx rdx, byte [rax + rcx * winStateLenPadded + winStates]  ; rdx = (uint8_t)boardIndex;                           Get the boardIndex stored in winStates[rcx][rax]
                mov bh, byte [rdx + board]                                   ; bh = (char)stateAtIndex;                             Get the stateAtIndex of the boardIndex(rdx)
                cmp bl, bh                                                   ;                                                      Compare stateAtIndex(bh) with currentPlayerSymbol(bl)
                jne _detectWinState_foreach_boardIndex_winState_END          ; if bh != bl: break @WinState; else:                  If the current player does not control this square then he or she cannot win with this winState
                inc al                                                       ; ++al;                                                Look at the next index in this winState
                cmp al, winStateLenRelevant                                  ;                                                      Compare winStateIndex(al) with 3
                jl _detectWinState_foreach_boardIndex_winState               ; if al < 3: continue @WinState; else:                 If not all 3 indices in this winState have been checked then continue checking them
                mov al, 0x01                                                 ; al = true;                                           The currentPlayer has won, so set the return value to true
                jmp _detectWinState_foreach_winState_winStates_END           ; break @WinStates;
            _detectWinState_foreach_boardIndex_winState_END:
            inc rcx                                        ; ++rcx;                                                                 Look at the next winState
            cmp rcx, winStatesLen / winStateLenPadded      ;                                                                        Compare currentWinState(rcx) to winStatesLen / winStateLenPadded
            jl _detectWinState_foreach_winState_winStates  ; if rcx < winStatesLen / winStateLenPadded: continue @WinStates; else:  If not all winStates have been checked then continue checking them
            xor al, al                                     ; al = false;                                                            The currentPlayer has not won, so set the return value to false
        _detectWinState_foreach_winState_winStates_END:
        pop rdx
        pop rcx
        pop rbx
        ret

    ; Takes    :
    ; Clobbers :
    ; Returns  : al = (bool)currentPlayerWon
    ; @todo This function could maybe(?) benefit from SIMD - A fun exercise and learning opportunity
    ; Sets all values in the board
    clearBoard:
        push ax      ; al is (uint8_t)currentLocation, ah is (char)newState
        xor al, al   ; al = (uint8_t)currentLocation;
        mov ah, ' '  ; ah = ' '
        _clearBoard_foreach_boardIndicesLen:        ; @Indices for al in 0..boardIndicesLen
            call setBoardLocationState              ; setBoardLocationState(al, ah);                     Sets the board's state at the currentLocation(al) to newState(ah)
            inc al                                  ; ++al;                                              Look at the next location
            cmp al, boardIndicesLen                 ;                                                    Compare the currentLocation(al) and the number of locations (boardIndicesLen)
            jl _clearBoard_foreach_boardIndicesLen  ; if al < boardIndicesLen: continue @Indices; else:  If not all board indices have been filled continue filling them
        pop ax
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
        mov rbx, userInputLen  ; rbx = (uint64_t)userInputLen;                                                 Used by all following SystemRead calls
        xor cl, cl             ; cl = false;                                                                   Buffer has not been overrun
        _collectInputByte_while_lastReadByteNot0x0A:            ; @Read while lastReadByte != 0x0A:
            lea rax, [userInput]                                ; rax = (char*)userInput;                      Used by the following SystemRead calls
            call SystemRead                                     ; rax = read(rax, rbx);                        bytesRead(rax) is set after attempting to read bufferBytes(rbx) bytes into buffer(rax)
            cmp byte [rax + userInput - 1], 0x0A                ;                                              Compare the last byte that was read into the buffer with the newline character
            je _collectInputByte_while_lastReadByteNot0x0A_END  ; if lastReadByte == '\n': break @Read; else:  If the last read byte is a newline character then the entire input has been buffered, so exit the loop
            mov cl, 0x01                                        ; cl = true;                                   The buffer has been overrun, so set bufferOverrun(cl) to true
            jmp _collectInputByte_while_lastReadByteNot0x0A     ; continue @Read;                              Read in the next bit of the buffer
        _collectInputByte_while_lastReadByteNot0x0A_END:
        test cl, cl                           ;                                                                Was the buffer overrun
        jne _collectInputByte_returns_false   ; if cl: return false; else:                                     If so, return false
        cmp rax, 0x02                         ;                                                                Was exactly 2 bytes read
        jne _collectInputByte_returns_false   ; if rax != 2: return false; else:                               If not, return false
        movzx rax, byte [userInput]           ; rax[al] = ((char*)userInput)[0];                               We only care about the first byte of input, not the newline character
        sub al, '1'                           ; al -= '1';                                                     Converts input(al) into the numeric value of input(al) - 1
        test al, al                           ;                                                                Is input(al) less than zero
        jl _collectInputByte_returns_false    ; if al < 0: return false; else:                                 If so, return false
        cmp al, 0x08                          ;                                                                Is input(al) greater than 8
        jg _collectInputByte_returns_false    ; if al > 8: return false; else:                                 If so return false
        mov [userInput], al                   ; *(char*)userInput = al;                                        Put the numeric value back into userInput for later use
        call getBoardLocationState            ; rax = boardStateAtLocation(al);                                Gets the board state at the location given in input(al)
        cmp al, ' '                           ;                                                                Compare the queried state(al) with the empty state
        jne _collectInputByte_returns_false   ; if al != ' ': return false; else:                              If state(al) is not the empty state, then early exit returning false
        mov rax, 0x01                         ; rax = true;                                                    All checks passed, so this function should return true
        jmp _collectInputByte_return
        _collectInputByte_returns_false:
        xor rax, rax                          ; rax = false;                                                   One of the above checks failed, the input is invalid, so this function should return false
        _collectInputByte_return:
        pop cx
        pop rbx
        ret