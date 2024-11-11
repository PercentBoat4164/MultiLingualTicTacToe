# MultiLingualTicTacToe

A simple implementation of Tic-Tac-Toe in a variety of programming languages

## Implementation Specifications

**Golden Rule:** The program’s output should be indistinguishable from that of other languages.

The board should be defined as a box made from Unicode box drawing characters. The board will be filled with numbers representing the index of that box, and the number that the user should input to place a piece at that location. There should never be a trailing new line at the end of the program’s output.  Copy from the example board below to get the Unicode characters required.
```
 1 │ 2 │ 3
───┼───┼───
 4 │ 5 │ 6
───┼───┼───
 7 │ 8 │ 9
```
As with standard tic-tac-toe, player 1 will play with the 'X' piece and player 2 will play with 'O'. The prompt to start the game should be displayed as:
```
You will be asked to enter a number 1-9. The number that you choose directly corresponds to the square that you go in as shown on the example board below. 'X' will go first. 'O' will go second. Each square can only be entered once. Put three of your piece in a row to win.

Tic-Tac-Toe
 1 │ 2 │ 3
───┼───┼───
 4 │ 5 │ 6
───┼───┼───
 7 │ 8 │ 9 

X:
```
The program will then wait for an input from the user and reject it, asking for a new input, if the user enters anything that is not a number between 1 and 9 and does not correspond to a square that has already been entered. The request for correct data should look like this:
```
That does not correspond to an available square. Please try again.
X:
```
Once a correct input has been given, the program should move on to the next player’s turn:
```
Tic-Tac-Toe
 X │   │   
───┼───┼───
   │   │   
───┼───┼───
   │   │   

O:
```
The program should again reject incorrect inputs in the same manner as above. Once valid input has been given, the program will repeat this until a game end condition is met. Upon a tie or 'Cat's Game', the program should output:
```
Tic-Tac-Toe
 X │ O │ X
───┼───┼───
 X │ X │ O
───┼───┼───
 O │ X │ O 
Game over. No winner.
```
Under the condition that a player actually wins, the program should display:
```
Tic-Tac-Toe
 X │ X │ X
───┼───┼───
 X │ O │ O
───┼───┼───
 O │ X │ O 
Game over. X wins!
```
After the game has ended, the program should promptly exit with code `0`.
