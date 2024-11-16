board = {[1]=10,[2]=84,[3]=105,[4]=99,[5]=45,[6]=84,[7]=97,[8]=99,[9]=45,[10]=84,[11]=111,[12]=101,[13]=10,[14]=32,[15]=49,[16]=32,[17]=226,[18]=148,[19]=130,[20]=32,[21]=50,[22]=32,[23]=226,[24]=148,[25]=130,[26]=32,[27]=51,[28]=32,[29]=10,[30]=226,[31]=148,[32]=128,[33]=226,[34]=148,[35]=128,[36]=226,[37]=148,[38]=128,[39]=226,[40]=148,[41]=188,[42]=226,[43]=148,[44]=128,[45]=226,[46]=148,[47]=128,[48]=226,[49]=148,[50]=128,[51]=226,[52]=148,[53]=188,[54]=226,[55]=148,[56]=128,[57]=226,[58]=148,[59]=128,[60]=226,[61]=148,[62]=128,[63]=10,[64]=32,[65]=52,[66]=32,[67]=226,[68]=148,[69]=130,[70]=32,[71]=53,[72]=32,[73]=226,[74]=148,[75]=130,[76]=32,[77]=54,[78]=32,[79]=10,[80]=226,[81]=148,[82]=128,[83]=226,[84]=148,[85]=128,[86]=226,[87]=148,[88]=128,[89]=226,[90]=148,[91]=188,[92]=226,[93]=148,[94]=128,[95]=226,[96]=148,[97]=128,[98]=226,[99]=148,[100]=128,[101]=226,[102]=148,[103]=188,[104]=226,[105]=148,[106]=128,[107]=226,[108]=148,[109]=128,[110]=226,[111]=148,[112]=128,[113]=10,[114]=32,[115]=55,[116]=32,[117]=226,[118]=148,[119]=130,[120]=32,[121]=56,[122]=32,[123]=226,[124]=148,[125]=130,[126]=32,[127]=57,[128]=32,[129]=10,[130]=10 }
boardIndices = {[1]=0x0F,[2]=0x15,[3]=0x1B,[4]=0x41,[5]=0x47,[6]=0x4D,[7]=0x73,[8]=0x79,[9]=0x7F}
playerSymbols = "XO"
currentPlayer = 0x1
currentPlayerSymbol = 'X'
winStates = {[1]={[1]=0x1B,[2]=0x15,[3]=0x0F}, [2]={[1]=0x4D,[2]=0x47,[3]=0x41}, [3]={[1]=0x7F,[2]=0x79,[3]=0x73}, [4]={[1]=0x73,[2]=0x41,[3]=0x0F}, [5]={[1]=0x79,[2]=0x47,[3]=0x15}, [6]={[1]=0x7F,[2]=0x4D,[3]=0x1B}, [7]={[1]=0x7F,[2]=0x47,[3]=0x0F}, [8]={[1]=0x73,[2]=0x47,[3]=0x1B}}

function stringifyBoard()
    local bytes = {}
    for _, v in ipairs(board) do table.insert(bytes, string.char(v)) end
    return table.concat(bytes)
end

function getBoardLocationState(location)
    local index = boardIndices[location]
    return board[index]
end

function setBoardLocationState(location, state)
    local index = boardIndices[location]
    board[index] = state
end

function isInWinState()
    local target = currentPlayerSymbol:byte(1)
    for _, winState in ipairs(winStates) do if board[winState[1]] == target and board[winState[2]] == target and board[winState[3]] == target then return true end end
    return false
end

io.write("You will be asked to enter a number 1-9. The number that you choose directly corresponds to the square that you go in as shown on the example board below. ‘X’ will go first. ‘O’ will go second. Each square can only be entered once. Put three of your piece in a row to win.\n")
io.write(stringifyBoard())
for location = 1, 9 do
    setBoardLocationState(location, 0x20)
end
local playerWon = false
for _ = 1, 9 do
    local input
    while true do
        io.write(currentPlayerSymbol, ": ")
        io.flush()
        input = io.read():match("^%d$")
        if input ~= nil then
            input = input:byte() - 0x30  -- '0'
        end
        if input == nil or input < 1 or input > 9 or not (getBoardLocationState(input) == 0x20) then
            io.write("That does not correspond to an available square. Please try again.\n")
        else
            break
        end
    end
    setBoardLocationState(input, currentPlayerSymbol:byte(1))
    io.write(stringifyBoard())
    playerWon = isInWinState()
    if playerWon then
        break
    end
    currentPlayer = currentPlayer ~ 3
    currentPlayerSymbol = playerSymbols:sub(currentPlayer, currentPlayer)
end
if playerWon then
    io.write("Game over. ", currentPlayerSymbol, " wins!")
else
    io.write("Game over. No winner.")
end