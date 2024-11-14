Board = require('Board')
local board = Board:new()
io.write("You will be asked to enter a number 1-9. The number that you choose directly corresponds to the square that you go in as shown on the example board below. ‘X’ will go first. ‘O’ will go second. Each square can only be entered once. Put three of your piece in a row to win.\n")
io.write(board:buildString())
board:clear();
for _ = 1, 10 do
    local input
    while true do
        -- @todo Add prompt
        io.flush()
        input = io.read():match("^%d$")
        if input ~= nil then
            input = input:byte() - 0x30
        end
        if input == nil or input < 1 or input > 9 then
            io.write("That does not correspond to an available square. Please try again.\n")
        else
            break
        end
    end
    local winner = board:takeTurn(input)
end