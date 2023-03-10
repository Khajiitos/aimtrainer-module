--[[
    Text areas:

    1 - Help
    2 - Start button
    3 - The game
    4 - Score
    5 - Time left
    6-8 - Squares
    9 - Square color button

    Popups:

    1 - Help popup
    2 - GG! score popup
    
    Color pickers:

    1 - Square color
]]

function openHelpPopup(playerName)
    local text = [[
<p align='center'><font size='20' color='#BABD2F'><b>Aim Trainer</b></font></p>
<b>Welcome to the module!</b>

This module will put your mouse aiming ability to a test.

By clicking the <b>Start</b> button, the minigame will start.

You will have <b>3</b> squares on the screen in random positions.
By clicking on one, its position will change.

The goal is to click as many of these squares as you can in <font color="#2EBA7E"><b>30</b> seconds</font>.

<p align='right'><font color='#606090' size='10'><b><i>Made by Khajiitos#0000</i><b></font></p>]]
    ui.addPopup(1, 0, text, playerName, 200, 75, 400, true)
end

AimTrainerGame = {
    player = nil,
    squares = {},
    score = 0,
    timeLeft = 30
}

PlayerData = {
    game = nil,
    squareColor = 0xFF0000,
    bestScore = 0
}

playerData = {}

function generateSquarePosition()
    local x = math.random(5, 765)
    local y
    if x <= 175 then
        y = math.random(85, 365)
    else
        y = math.random(30, 365)
    end
    return x, y
end

function PlayerData:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function AimTrainerGame:new(player)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.player = player
    o.squares = {}
    return o
end

function AimTrainerGame:start()
    tfm.exec.freezePlayer(self.player, true)
    tfm.exec.setNameColor(self.player, playerData[self.player].squareColor)
    ui.addTextArea(3, "", self.player, 5, 5, 790, 390, nil, nil, 1.0, true)

    for i = 6, 8 do
        local squareX, squareY = generateSquarePosition()
        self.squares[#self.squares + 1] = {
            x = squareX,
            y = squareY,
            textAreaID = i,
            squareNum = #self.squares + 1
        }
        ui.addTextArea(i, string.format('<a href="event:square%d"><font size="128">a</font></a>', #self.squares), self.player, squareX, squareY, 25, 25, playerData[self.player].squareColor, 0x324650, 1.0, true)
    end
    ui.addTextArea(4, "", self.player, 5, 30, 0, 25, nil, nil, 9.0, true)
    ui.addTextArea(5, "", self.player, 5, 55, 0, 25, nil, nil, 9.0, true)
    self:updateScoreAndTime()
end

function AimTrainerGame:finish()
    tfm.exec.freezePlayer(self.player, false)
    tfm.exec.setNameColor(self.player, 0xFFFFFF)
    for i = 3, 8 do
        ui.removeTextArea(i, self.player)
    end
    ui.addPopup(2, 0, string.format('<p align="center"><font size="18" color="#00FF00"><b>GG!</b></font></p>\nYour score: <b>%d</b>', self.score), self.player, 300, 150, 200, true)
    if self.score > playerData[self.player].bestScore then
        playerData[self.player].bestScore = self.score
        tfm.exec.setPlayerScore(self.player, self.score, false)
    end
end

function AimTrainerGame:updateScoreAndTime()
    ui.updateTextArea(4, string.format("<font size='16'><b>Score:</b> %d</font>", self.score), self.player)
    ui.updateTextArea(5, string.format("<font size='16'><b>Time left:</b> %1.f s</font>", self.timeLeft), self.player)
end

function AimTrainerGame:onClickSquare(squareNumber)
    self.score = self.score + 1
    self:updateScoreAndTime()
    ui.removeTextArea(self.squares[squareNumber].textAreaID, self.player)

    local squareX, squareY = generateSquarePosition()

    self.squares[squareNumber].x = squareX
    self.squares[squareNumber].y = squareY

    ui.addTextArea(self.squares[squareNumber].textAreaID, string.format('<a href="event:square%d"><font size="128">a</font></a>', self.squares[squareNumber].squareNum), self.player, squareX, squareY, 25, 25, playerData[self.player].squareColor, 0x324650, 1.0, true)
end

function eventTextAreaCallback(textAreaID, playerName, callback)
    if callback == "helpQuestionMark" then
        openHelpPopup(playerName)
    elseif callback == "start" then
        if not playerData[playerName].game then
            local game = AimTrainerGame:new(playerName)
            playerData[playerName].game = game
            game:start()
        end
    elseif callback == "squareColor" then
        ui.showColorPicker(1, playerName, playerData[playerName].squareColor, "Square color")
    end

    for squareNum in callback:gmatch('square(%d)') do
        local game = playerData[playerName].game
        if game then
            game:onClickSquare(tonumber(squareNum))
            break
        end
    end
end

function eventColorPicked(colorPickerId, playerName, color)
    if colorPickerId == 1 then
        if color ~= -1 then
            updateSquareColor(playerName, color)
        end
    end
end

function eventLoop(currentTime, timeRemaining)
    local toRemove = {}
    for player, playerData in pairs(playerData) do
        local game = playerData.game
        if game then
            game.timeLeft = game.timeLeft - 0.5
            game:updateScoreAndTime()
            if game.timeLeft <= 0 then
                game:finish()
                toRemove[#toRemove + 1] = player
            end
        end
    end
    for i, playerToRemove in pairs(toRemove) do
        playerData[playerToRemove].game = nil
    end
end

function eventChatCommand(playerName, message)
    local args = {}
    for arg in message:gmatch("%S+") do
        args[#args + 1] = arg
    end
    local command = table.remove(args, 1)

    if command == "help" then
        openHelpPopup(playerName)
    elseif command == "exit" then
        if playerData[playerName].game then
            playerData[playerName].game:finish()
            playerData[playerName].game = nil
        end
    end
end

function invertColor(color)
    local strColor = string.format("%06X", color)
    local r = tonumber(string.sub(strColor, 1, 2), 16)
    local g = tonumber(string.sub(strColor, 3, 4), 16)
    local b = tonumber(string.sub(strColor, 5, 6), 16)
    local invertedStrColor = string.format("%02X", 255 - r) .. string.format("%02X", 255 - g) .. string.format("%02X", 255 - b)
    return tonumber(invertedStrColor, 16)
end

function updateSquareColor(playerName, color)
    if color == 0xFFFFFF then
        color = 0xFEFEFE
    elseif color == 0x000000 then
        color = 0x010101
    end
    playerData[playerName].squareColor = color
    ui.addTextArea(9, string.format("<a href='event:squareColor'><p align='center'><font size='13' color='#%06X'><b>Square color</b></font></p></a>", invertColor(color)), playerName, 10, 35, 120, 20, color, color, 1.0, true)
end

function initPlayer(playerName)
    playerData[playerName] = PlayerData:new()
    system.bindMouse(playerName, true)
    ui.addTextArea(1, "<a href='event:helpQuestionMark'><p align='center'><font size='16'><b>?</b></font></p></a>", playerName, 760, 35, 25, 25, 0x111111, 0x111111, 1.0, true)
    ui.addTextArea(2, "<a href='event:start'><p align='center'><font size='16'><b>Start</b></font></p></a>", playerName, 350, 360, 100, 25, nil, nil, 1.0, true)
    updateSquareColor(playerName, 0xFF0000)
    tfm.exec.respawnPlayer(playerName)
    tfm.exec.setNameColor(playerName, 0xFFFFFF)
end

function eventNewPlayer(playerName)
	initPlayer(playerName)
end

function eventPlayerDied(playerName)
    tfm.exec.respawnPlayer(playerName)
end

function eventPlayerLeft(playerName)
    if playerData[playerName].game then
        playerData[playerName].game = nil
    end
end

for playerName in pairs(tfm.get.room.playerList) do
    initPlayer(playerName)
end

tfm.exec.disableAfkDeath(true)
tfm.exec.disableAutoNewGame(true)
tfm.exec.disableAutoScore(true)
tfm.exec.disableAutoShaman(true)
tfm.exec.disableAutoTimeLeft(true)
tfm.exec.disablePhysicalConsumables(true)
tfm.exec.newGame(0, true)
tfm.exec.setGameTime(0, true)

system.disableChatCommandDisplay("help", true)
system.disableChatCommandDisplay("exit", true)