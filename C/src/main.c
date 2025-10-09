#include <stdio.h>
#include <stdbool.h>
#include <locale.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

// the board upon which the game will be played
struct board {
    wchar_t gameBoard[9]; // stores locations of past moves, X's and O's
    bool isPlayer1sTurn; // True -> player one has next move, False -> player two has next move
    const wchar_t vDivider[4]; // How a vertical divider one line tall will be drawn
    const wchar_t hDivider[14]; // How a horizontal divider across the whole board will be drawn
    int winConditions[8][3]; // All
};

typedef struct board Board ;

// draw a row from the gameBoard. top is origin for y.
void drawRow(Board *board, int y)
{
    wprintf(L" "); //aligns vertical with horizontal
    for(int x = 0; x < 2; x++) {
        wprintf(L"%c", board->gameBoard[3 * y + x]);
        wprintf(L"%ls", board->vDivider);
    }
}

// draw the gameBoard in the console
void drawBoard(Board *board) {

    wprintf(L"Tic-Tac-Toe\n");
    //loop through rows until whole board is drawn
    for(int y = 0; y < 2; y++) {
    drawRow(board, y);
        //draw a row followed by the horizontal divider
        wprintf(L"%c", board->gameBoard[3 * y + 2]);
        wprintf(L"%ls", board->hDivider);
    }
    drawRow(board, 2);
    wprintf(L"%c", board->gameBoard[8]);
    wprintf(L" \n");
}

// Apply a move to the board. returns true if successful
bool resolveMove(int location, Board *board) {
    wchar_t currPlayer = (board->isPlayer1sTurn) ? 'X' : 'O';
    //ensure chosen square is available
    if (board->gameBoard[location] != 'X' && board->gameBoard[location] != 'O')
    {
        board->gameBoard[location] = currPlayer;
        return true;
    }
    return false;
}

// Check for win conditions
bool checkForWin(const Board *board) {

    const wchar_t currPlayer = (!board->isPlayer1sTurn) ? 'X' : 'O';

    //check every win condition
    for (int i = 0; i < sizeof(board->winConditions) / sizeof(board->winConditions[0]); i++)
    {
        //check current win condition
        int matches = 0;
        for (int j = 0; j < sizeof(board->winConditions[i]) / sizeof(board->winConditions[0][0]); j++)
        {
            if (board->gameBoard[board->winConditions[i][j]] == currPlayer)
            {
                matches++;
            } else
            {
                break;
            }
        }
        if (matches >= sizeof(board->winConditions[i]) / sizeof(board->winConditions[0][0]))
        {
            wprintf(L"Game over. ");
            wprintf(L"%c", currPlayer);
            wprintf(L" wins! \n");
            return true;
        }
    }
    return false;
}

// Check for a filled gameboard
bool checkForFullBoard(Board *board)
{
    for (int i = 0; i < sizeof(board->gameBoard) / sizeof(board->gameBoard[0]); i++)
    {
        if (board->gameBoard[i] == '\0')
        {
            return false;
        }
    }
    wprintf(L"Game over. No winner.");
    return true;
}

// initialize a game
Board initGame() {
    wprintf(L"\nYou will be asked to enter a number 1-9. The number that you choose directly corresponds to the square that you go in as shown on the example board below. 'X' will go first. 'O' will go second. Each square can only be entered once. Put three of your piece in a row to win.\n\n");
    wprintf(L" 1 │ 2 │ 3\n───┼───┼───\n 4 │ 5 │ 6\n───┼───┼───\n 7 │ 8 │ 9\n");
    Board newBoard = {{'\0'}, true, L" │ ", L"\n───┼───┼───\n",};
    memcpy(newBoard.winConditions, (int[8][3]){{0, 1, 2}, {3, 4, 5}, {6, 7, 8}, {0, 3, 6}, {1, 4, 7}, {2, 5, 8}, {0, 4, 8}, {2, 4, 6}}, sizeof(newBoard.winConditions));
    return newBoard;
}

// get a move from the player
int getMove(bool isPlayer1sTurn) {
    int out = -1;
    char buf[256];
    //prompt player
    if (isPlayer1sTurn) {
        wprintf(L"\nX: ");
    } else {
        wprintf(L"\nO: ");
    }

    //scan for input
    if (fgets(buf, sizeof buf, stdin)) {
        out = atol(buf); //convert input to int
        //validate & return input
        if (1 <= out && out <= 9 && buf[1] == '\n')
        {
            wprintf(L"\n");
            return out;
        }
    }
    //if not, reading input failed
    return -1;
}

int main(void) {

    setlocale(LC_ALL, ""); // allows printing of platform-dependent text (box characters in this case)

    Board board = initGame();

    do {
        int moveCandidate = getMove(board.isPlayer1sTurn) - 1;
        if (moveCandidate >= 0 && resolveMove(moveCandidate, &board)) {
            drawBoard(&board);
            board.isPlayer1sTurn = !board.isPlayer1sTurn;
        } else {
            wprintf(L"That does not correspond to an available square. Please try again.\n");
        }
    } while (!checkForWin(&board) && !checkForFullBoard(&board));

    return 0;
}
