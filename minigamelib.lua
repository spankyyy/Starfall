--@name minigamelib
--@author
--@server

-- Library...
local mglib = {}
mglib.players = {}
mglib.debug = true

-- Creates game and team types (classes)
local mgame = class("game")
local mteam = class("team")
local mplayer = class("player")

-- Fancy print c:
function mglib.debugPrint(...)
    if mglib.debug then
        Color(128, 255, 128)
        print(Color(0, 0, 0), "[", Color(128, 255, 128), "MinigameLib", Color(0, 0, 0), "] - ", Color(0, 255, 0), ...)
    end
end

-- Runs trought all players and creates a class for them
function mglib.createPlayerClasses()
    local temporaryPlayerTable = {}
    for k, v in pairs(find.allPlayers()) do
        local newPlayer = mplayer:new(v)
        table.addValue(temporaryPlayerTable, newPlayer)
    end
    mglib.players = temporaryPlayerTable
end

-- Adds a value onto a table
function table.addValue(tbl, value)
    tbl[#tbl+1] = value
end

-- Removes a value from a table
function table.removeValue(tbl, value)
    table.removeByValue(tbl, value)
end

-- Runs on the creation of a new player (mplayer:new(...))
function mplayer:initialize(playerEntity)
    if playerEntity.player ~= nil then
        self = playerEntity.player
        else
        self.playerEntity = playerEntity
        self.team = {}
        playerEntity.player = self
    end
end

-- Runs on the creation of a new game (mgame:new(...))
function mgame:initialize(players, teams)
    mglib.debugPrint("Creating new game")
    self.players = players or {}
    self.teams = teams  or {}
end

-- Runs on the creation of a new team (mteam:new(...))
function mteam:initialize(name, color, players, deadPlayers)
    mglib.debugPrint("Creating new team named " .. name)
    self.name = name
    self.color = color
    self.players = players or {}
    self.deadPlayers = deadPlayers or {}
end

-- Adds a team to a game
function mgame:addTeam(team)
    mglib.debugPrint("Added team " .. team.name .. " to the game")
    local teamName = team.name
    self.teams[teamName] = team
end

-- Gets a team from the game
function mgame:getTeam(name)
    return self.teams[name]
end

-- Adjusts players in the game
function mgame:adjustPlayers(players)
    mglib.debugPrint("Adjusted players in the game")
    self.players = players
end

-- Adds player(s) in the game
function mgame:addPlayer(player)
    mglib.debugPrint("Added a player to the game")
    table.addValue(self.players, player)
end

-- Remove player(s) from the game
function mgame:removePlayer(player)
    mglib.debugPrint("Removed a player from the game")
    table.removeValue(self.players, player)
end

-- Adjusts players in the team
function mteam:adjustPlayers(players)
    mglib.debugPrint("Adjusted players in the team")
    self.players = players
    for k, v in pairs(self.players) do
        v.team = self
    end
end

-- Adds player(s) in the team
function mteam:addPlayer(player)
    mglib.debugPrint("Added a player to the team")
    table.addValue(self.players, player)
    for k, v in pairs(self.players) do
        v.team = self
    end
end

-- Remove player(s) from the team
function mteam:removePlayer(player)
    mglib.debugPrint("Removed a player from the team")
    table.removeValue(self.players, player)
    for k, v in pairs(self.players) do
        v.team = self
    end
end

-- Creates a new team with a color and a name
function mgame:createNewTeam(name, color, players)
    -- Create a new team
    local newteam = mteam:new(name, color, players or {}, {})
    self:addTeam(newteam)
end

-- Makes sure to give new players a player class
hook.add("PlayerInitialSpawn", "CreatePlayerClasses", function(ply, transition)
    mglib.debugPrint("New player joined server, creating player class")
    local player = mplayer:new(ply)
    table.addValue(mglib.players, player)
end)

--[ Example ]--
mglib.createPlayerClasses()
local newgame = mgame:new()
newgame:createNewTeam("Red", Color(255, 0, 0))
local newteam = newgame:getTeam("Red")
newteam:addPlayer(owner().player)


