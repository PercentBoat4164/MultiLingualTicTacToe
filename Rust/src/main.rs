use std::io::Write;

mod board;

fn get_valid_input(board: &board::Board) -> u8 {
    let mut buf = String::new();
    print!("{}: ", board.player);
    std::io::stdout().flush().unwrap();
    loop {
        std::io::stdin().read_line(&mut buf).unwrap();
        let input = buf.as_bytes()[0].wrapping_sub('0' as u8 + 1);
        if buf.len() == 2 && input <= 8 && board.location_is_available(input) { return input }
        buf.clear();
        print!("That does not correspond to an available square. Please try again.\n{}: ", board.player);
        std::io::stdout().flush().unwrap();
    }
}

fn main() {
    let mut board = board::Board::new();
    println!("You will be asked to enter a number 1-9. The number that you choose directly corresponds to the square that you go in as shown on the example board below. ‘X’ will go first. ‘O’ will go second. Each square can only be entered once. Put three of your piece in a row to win.");
    print!("{}", board);
    board.clear();
    for _ in 0..9 {
        println!();
        let input = get_valid_input(&mut board);
        let should_break = board.take_turn(input as usize);
        print!("{}", board);
        if should_break { break; }
    }
    if board.is_in_win_state() { println!("Game over. {} wins!", board.player); }
    else { println!("Game over. No winner."); }
}
