--@name minigamelib
--@author
--@shared
--[[ How to use 

    >CAN ONLY BE USED ON SERVER<

--@include libraries/minigame.txt
require("libraries/minigame.txt")

]]
if SERVER then
    
    -- Library...
    mglib = {}
    mglib.players = {}
    mglib.games = {}
    
    -- Creates game and team types (classes)
    mgame = class("game")
    mteam = class("team")
    mplayer = class("player")
    
    -- Fancy print c:
    function mglib.debugPrint(...)
        if mglib.debug then
            Color(128, 255, 128)
            print(Color(0, 0, 0), "[", Color(128, 255, 128), "MinigameLib", Color(0, 0, 0), "] - ", Color(0, 255, 0), ...)
        end
    end
    
    -- Runs through all players and creates a class for them
    function mglib.createPlayerClasses()
        local temporaryPlayerTable = {}
        for k, v in pairs(find.allPlayers()) do
            local newPlayer = mplayer:new(v)
            mglib.addValue(temporaryPlayerTable, newPlayer)
        end
        mglib.players = temporaryPlayerTable
    end
    
    -- Adds a value onto a table
    function mglib.addValue(tbl, value)
        tbl[#tbl+1] = value
    end
    function mglib.addIndexedValue(tbl, index, value)
        tbl[index] = value
    end
    
    -- Removes a value from a table
    function mglib.removeValue(tbl, value)
        table.removeByValue(tbl, value)
    end
    
    -- Runs on the creation of a new player (mplayer:new(...))
    function mplayer:initialize(playerEntity)
        if playerEntity.player ~= nil then
            self = playerEntity.player
        else
            local name = playerEntity:getName()
            -- Entity to run stuff on like sounds
        
            local useableEntity = holograms.create(playerEntity:getPos(), Angle(), "models/hunter/blocks/cube025x025x025.mdl", Vector(1))
            useableEntity:setColor(Color(0, 0, 0, 0))
            useableEntity:setParent(playerEntity)
            self.playerEntity = playerEntity
            self.team = {}
            self.inTeam = false
            self.playerName = name
            self.isEliminated = false
            playerEntity.ballTeamKeep = true
            playerEntity.player = self
            playerEntity.isMG = true
            playerEntity.playerName = name
            playerEntity.useableEntity = useableEntity
        end
    end
    
    -- Runs on the creation of a new game (mgame:new(...))
    function mgame:initialize(name, players, teams)
        mglib.debugPrint("Creating new game")
        self.players = players or {}
        self.teams = teams  or {}
        self.name = name
        mglib.addIndexedValue(mglib.games, name, self)
    end
    
    -- Runs on the creation of a new team (mteam:new(...))
    function mteam:initialize(name, game, color, players, deadPlayers)
        local name = string.lower(name)
        mglib.debugPrint("Creating new team named " .. name)
        self.name = name
        self.color = color
        self.players = players or {}
        self.deadPlayers = deadPlayers or {}
        self.game = game
    end
    
    -- Adds a team to a game
    function mgame:addTeam(team)
        mglib.debugPrint("Added team " .. team.name .. " to the game")
        self.teams[team.name] = team
    end
    
    -- Gets a team from the game
    function mgame:getTeam(name)
        return self.teams[name]
    end
    
    function networkPlyList(self)
        local temp = {}
        for k, v in pairs(self.players) do
            temp[#temp+1] = {
                plyname = v.playerName, 
                team = v.team.name,
                color = v.team.color
            }
        end
        safeNet.start("gameplylist")
        safeNet.writeString(self.name)
        safeNet.writeTable(temp)
        safeNet.send(self.players)
    end
    
    -- Adjusts players in the game
    function mgame:adjustPlayers(players)
        mglib.debugPrint("Adjusted players in the game")
        self.players = players
        networkPlyList(self)
    end
    
    -- Adds player(s) in the game
    function mgame:addPlayer(player)
        mglib.debugPrint("Added a player to the game")
        mglib.addValue(self.players, player)
        networkPlyList(self)
    end
    
    -- Remove player(s) from the game
    function mgame:removePlayer(player)
        mglib.debugPrint("Removed a player from the game")
        mglib.removeValue(self.players, player)
        networkPlyList(self)
    end
    
    -- Adjusts players in the team
    function mteam:adjustPlayers(players)
        mglib.debugPrint("Adjusted players in the team")
        self.players = players
        
        for k, v in pairs(self.players) do
            v.team = self
            v.inTeam = true
        end
        local plyListTemp = {}
        for k, v in pairs(self.game.teams) do
            for k_, v_ in pairs(v.players) do
                mglib.addValue(plyListTemp, v_)
            end
        end
        self.game.players = plyListTemp
        networkPlyList(self.game)
    end
    
    -- Adds player(s) in the team
    function mteam:addPlayer(player)
        mglib.debugPrint("Added a player to the team")
        mglib.addValue(self.players, player)
        
        player.inTeam = true
        player.team = self
        local plyListTemp = {}
        for k, v in pairs(self.game.teams) do
            for k_, v_ in pairs(v.players) do
                mglib.addValue(plyListTemp, v_)
            end
        end
        self.game.players = plyListTemp
        networkPlyList(self.game)
    end
    
    -- Remove player(s) from the team
    function mteam:removePlayer(player)
        mglib.debugPrint("Removed a player from the team")
        mglib.removeValue(self.players, player)
        
        v.team = nil
        v.inTeam = false
        local plyListTemp = {}
        for k, v in pairs(self.game.teams) do
            for k_, v_ in pairs(v.players) do
                mglib.addValue(plyListTemp, v_)
            end
        end
        self.game.players = plyListTemp
        networkPlyList(self.game)
    end
    
    -- Returns the players in the team
    function mteam:getPlayers(pretty)
        local tmp = {}
        for k, v in pairs(self.players) do
            mglib.addValue(tmp, v.playerEntity)
            if pretty then
                if v.team.teamName ~= nil then
                    mglib.addValue(tmp, "IN TEAM " .. v.team.teamName)
                else
                    mglib.addValue(tmp, "NOT IN A TEAM")
                end
            end
        end
        return tmp
    end
    
    -- Returns the players in the game
    function mgame:getPlayers(prett)
        local tmp = {}
        for k, v in pairs(self.players) do
            mglib.addValue(tmp, v.playerEntity)
            if pretty then
                if v.team.name ~= nil then
                    mglib.addValue(tmp, "IN TEAM " .. v.team.name)
                else
                    mglib.addValue(tmp, "NOT IN A TEAM")
                end
            end
        end
        return tmp
    end
      
    -- Creates a new team with a color and a name
    function mgame:createNewTeam(name, color, players)
        -- Create a new team
        local newteam = mteam:new(name, self, color)
        self:addTeam(newteam)
        return newteam
    end
    
    -- Makes sure to give new players a player class
    hook.add("PlayerInitialSpawn", "CreatePlayerClasses", function(ply, transition)
        mglib.debugPrint("New player joined server, creating player class")
        local player = mplayer:new(ply)
        mglib.addValue(mglib.players, player)
    end)
    mglib.createPlayerClasses()
end
