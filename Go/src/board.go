package main

import (
	"fmt"
)

type Board struct {
	player        uint8
	playerIndex   uint
	playerSymbols string
	contents      string
	winStates     [8][3]uint8
}

func NewBoard() *Board {
	return &Board{player: 'X',
		playerSymbols: "XO",
		contents:      "123456789",
		winStates:     [8][3]uint8{{0, 1, 2}, {3, 4, 5}, {6, 7, 8}, {0, 3, 6}, {1, 4, 7}, {2, 5, 8}, {0, 4, 8}, {2, 4, 6}},
	}
}

func (board *Board) Draw() {
	_, _ = fmt.Printf("\nTic-Tac-Toe\n %c │ %c │ %c \n───┼───┼───\n %c │ %c │ %c \n───┼───┼───\n %c │ %c │ %c \n", board.contents[0], board.contents[1], board.contents[2], board.contents[3], board.contents[4], board.contents[5], board.contents[6], board.contents[7], board.contents[8])
}

func (board *Board) Clear() {
	board.contents = "         "
}

func (board *Board) TakeTurn(location byte) bool {
	out := []uint8(board.contents)
	out[location] = board.player
	board.contents = string(out)
	if board.IsInWinState() {
		return true
	}
	board.playerIndex ^= 1
	board.player = board.playerSymbols[board.playerIndex]
	return false
}

func (board *Board) LocationIsAvailable(location byte) bool {
	var sym = board.contents[location]
	return !(sym == 'X' || sym == 'O')
}

func (board *Board) IsInWinState() bool {
	for _, state := range board.winStates {
		if board.contents[state[0]] == board.player && board.contents[state[1]] == board.player && board.contents[state[2]] == board.player {
			return true
		}
	}
	return false
}
