use std::io::{Write};

mod board;

fn main() {
    let mut board = board::Board::default();
    println!("You will be asked to enter a number 1-9. The number that you choose directly corresponds to the square that you go in as shown on the example board below. ‘X’ will go first. ‘O’ will go second. Each square can only be entered once. Put three of your piece in a row to win.");
    println!("{}", board.build_string());
    let mut winner: char = ' ';
    board.clear();
    for _ in 0..9 {
        let mut input: u8;
        loop {
            print!("{}: ", board.player);
            std::io::stdout().lock().flush().expect("");
            let mut buf = String::new();
            std::io::stdin().read_line(&mut buf).unwrap();
            input = buf.as_bytes()[0].wrapping_sub(0x30);
            if buf.is_ascii() && input >= 0x01 && input <= 0x09 && board.is_valid(input - 1) { break; }
            println!("That does not correspond to an available square. Please try again.");
        }
        winner = board.take_turn((input - 1) as usize);
        println!("{}", board.build_string());
        if winner != '_' { break; }
    }
    if winner == '_' { println!("Game over. No winner."); }
    else { println!("Game over. {} wins!", winner); }
}
