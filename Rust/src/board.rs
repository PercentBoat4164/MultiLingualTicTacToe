use std::fmt::Display;

pub struct Board {
    pub(crate) player: char,
    player_index: u8,
    player_symbols: [char; 2],
    contents: [char; 9],
    win_states: [[u8; 3]; 8],
}

impl Display for Board {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let str = format!("\nTic-Tac-Toe\n {} │ {} │ {} \n───┼───┼───\n {} │ {} │ {} \n───┼───┼───\n {} │ {} │ {} \n", self.contents[0], self.contents[1], self.contents[2], self.contents[3], self.contents[4], self.contents[5], self.contents[6], self.contents[7], self.contents[8]);
        write!(f, "{}", str)
    }
}

impl Board {
    pub fn new() -> Self {
        Board {
            player: 'X',
            player_index: 0,
            player_symbols: ['X', 'O'],
            contents: ['1', '2', '3', '4', '5', '6', '7', '8', '9'],
            win_states: [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]],
        }
    }

    pub fn clear(&mut self) {
        self.contents = [' '; 9];
    }

    pub fn take_turn(&mut self, location: usize) -> bool {
        self.contents[location] = self.player;
        if self.is_in_win_state() { return true; }
        self.player_index ^= 1;
        self.player = self.player_symbols[self.player_index as usize];
        false
    }

    pub fn location_is_available(&self, location: u8) -> bool {
        let sym = self.contents[location as usize];
        !(sym == 'X' || sym == 'O')
    }
    
    pub fn is_in_win_state(&self) -> bool {
        for i in self.win_states {
            if self.contents[i[0] as usize] == self.player && self.contents[i[1] as usize] == self.player && self.contents[i[2] as usize] == self.player {
                return true;
            }
        }
        false
    }
}