package main

import (
	"bufio"
	"fmt"
	"os"
)

func getValidInput(board *Board) byte {
	var reader = bufio.NewReader(os.Stdin)
	fmt.Printf("%c: ", board.player)
	for {
		var buf, _ = reader.ReadString('\n')
		var input = buf[0] - ('0' + 1)
		if len(buf) == 2 && input <= 8 && board.LocationIsAvailable(input) {
			return input
		}
		fmt.Printf("That does not correspond to an available square. Please try again.\n%c: ", board.player)
	}
}

func main() {
	var board = NewBoard()
	println("You will be asked to enter a number 1-9. The number that you choose directly corresponds to the square that you go in as shown on the example board below. ‘X’ will go first. ‘O’ will go second. Each square can only be entered once. Put three of your piece in a row to win.")
	board.Draw()
	board.Clear()
	for i := 0; i < 9; i++ {
		println()
		var input = getValidInput(board)
		var shouldBreak = board.TakeTurn(input)
		board.Draw()
		if shouldBreak {
			break
		}
	}
	if board.IsInWinState() {
		fmt.Printf("Game over. %c wins!\n", board.player)
	} else {
		println("Game over. No winner.")
	}
}
