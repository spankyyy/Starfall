--@name Swerve
--@author
--@shared
--@include libraries/safenet.txt
require("libraries/safenet.txt")
safeNet = safeNet or net
if SERVER then
    -- Server
    
    --@include libraries/minigame.txt
    --@include libraries/extralib.txt
    --@include libraries/chatlib.txt
    require("libraries/minigame.txt")
    require("libraries/extralib.txt")
    require("libraries/chatlib.txt")
    mglib.debug = false
    ball = class("ball")
    local spawnBallsInfo = {}
    
    -- REVIVE ItemBattery.Touch
    -- TAGGED Metal.SawbladeStick
    local onGrabEnemyBall = function(ballClass, playerClass)
        -- Runs when you grab an enemy ball
        if ballClass.team.name ~= nil and ballClass.team.name ~= playerClass.team.name and not playerClass.isEliminated then
            print("caught enemy ball")
        end
    end
    local onGrabFunc = function(ply, ent)
        local newball, player = ent.ballClass, ply.player
        if ent.isDB and player ~= nil and ply.player.inTeam then
            newball:catch(player)
        end
    end
    local onBallCollision = function(data)
        local entity = data.Entity
        
        entity:setColor(Color(math.random(0, 255), math.random(0, 255), math.random(0, 255)))
        
        local hitEntity = data.HitEntity
        local ballClass = entity.ballClass
        local playerClass = hitEntity.player
        if hitEntity.ballTeamKeep == nil or hitEntity.ballTeamKeep == false then
            -- If the ball doesnt touch a KEEPTEAM entity then we reset
            ballClass:reset()
        elseif hitEntity.isMG then -- Checks if the entity is a player using isMG variable assigned at initialization of a player class
            local ballTeam = ballClass.team
            local playerTeam = playerClass.team
            local inflictor = ballClass.lastHeldBy
            -- Eliminate the player if in a team, not the same team and not eliminated and inflictor not eliminated
            if not inflictor.isEliminated and not playerClass.isEliminated and playerTeam.name ~= ballTeam.name and playerTeam.name and ballTeam.name and not entity:isPlayerHolding() then
                playerClass:eliminate(ballClass, inflictor)
            end
        end
        
        -- Adds impact sounds to the balls
        local neg = getVectorNegative(data.HitNormal)
        local volume = math.abs((data.OurNewVelocity * neg):getLength())
        volume = math.max((volume == volume) and volume + 1 or 0, 0) * 0.005 --volume ^ 3
        entity:emitSound("physics/rubber/rubber_tire_impact_hard3.wav", 75, math.random(140, 180), volume ^ 3, 6)
    end
    
    -- Spawns a ball
    function spawnBall(pos)
        local ent = prop.create(pos, Angle(0, 0, 0), "models/holograms/hq_sphere.mdl")
        ball:new(ent)
    end
    
    -- Spawns alot of balls
    function spawnBalls(amount, pos)
        -- Uses a coroutine to spawn multiple balls to prevent erroring from prop spawn limit (4 per second)
        spawnBallsInfo = {amount, pos}
        ballSpawnCoroutine = coroutine.create(function(amount, pos)
            coroutine.yield()
            for i = 1, amount do
                -- Waits a quarter second before resuming the coroutine
                coroutine.wait(1 / 4)
                spawnBall(pos)
            end
        end)
    end
    
    -- Freezes player (Requires the E2 Link)
    function freezePlayer(playerEntity)
        wire.ports.Player = playerEntity
        wire.ports.Clk = 1
        timer.simple(0.0001, function()
            wire.ports.Clk = 0
        end)
    end
    function ball:initialize(ballEntity)
        local obj = ballEntity:getPhysicsObject()
        self.entity = ballEntity
        self.lastHeldBy = {}
        self.held = false
        self.team = {}
        -- Makes the ball have a perfect sphere collision
        ballEntity:enableSphere(true)
        ballEntity.ballClass = self
        -- Atributes the entity with isDB (isDodgeBall)
        ballEntity.isDB = true
        ballEntity:setMaterial("sprops/textures/sprops_metal4")
        -- Gives the ball a bouncy material
        ballEntity:setPhysMaterial("gm_ps_soccerball")
        -- Listens to collision and runs a command on one
        ballEntity:collisionListener(onBallCollision)
    end
    function ball:catch(playerClass)
        if not self.held then
            local playerTeam = playerClass.team
            if self.team.name ~= nil and self.team.name ~= playerTeam.name then
                onGrabEnemyBall(self, playerClass)
            end
            self.lastHeldBy = playerClass
            self.held = true
            self.team = playerTeam
            self.entity:setColor(playerTeam.color)
        end
    end
    function ball:reset()
        if self.team ~= nil and not self.entity:isPlayerHolding() then
            self.lastHeldBy = {}
            self.team = {}
            self.held = false
            --self.entity:setColor(Color(255, 255, 255))
        end
    end
    function mplayer:eliminate(ballClass, inflictor)
        local playerEnt = self.playerEntity
        -- Resets the ball even so the player has KEEPTEAM 
        if ballClass then ballClass:reset() end
        playerEnt.useableEntity:emitSound("Metal.SawbladeStick", 75, math.random(140, 150), 1, 6)
        self.isEliminated = true
        freezePlayer(playerEnt)
        print("eliminated player " .. playerEnt.playerName .. " from team " .. self.team.name)
    end
    function mgame:networkPlayerListToClients()
        safeNet.start("gameplylist")
        safeNet.writeString(self.name)
        safeNet.send(self.players)
    end
    hook.add("think", "resumeCoroutine", function()
        if ballSpawnCoroutine then
            if coroutine.status(ballSpawnCoroutine) ~= "dead" then
                coroutine.resume(ballSpawnCoroutine, unpack(spawnBallsInfo))
            end
        end
    end)
    hook.add("GravGunOnPickedUp", "PickupBallGrav", onGrabFunc)
    hook.add("OnPlayerPhysicsPickup", "PickupBallHand", onGrabFunc)
    wire.adjustOutputs({"Player", "Clk"}, {"Entity", "Number"})
    
    
    -- Other logic
    local newgame = mgame:new("dodgeball")
    
    local red = newgame:createNewTeam("red", Color(255, 0, 0))
    local blue = newgame:createNewTeam("blue", Color(0, 0, 255))
    
    addChatCommand("a", function(ply, player, teamname)
        local _team = newgame.teams[teamname]
        if _team == nil then print("unvalid team") return end
        local _player = find.playersByName(player)[1]
        if _player == nil then print("unvalid player") return end
        _team:addPlayer(_player.player)
    end, {hideChat = false})
    
    spawnBalls(32, chip():getPos() + Vector(0, 0, 16))
    //dio.player:eliminate()
    
--[[
    timer.simple(1, function()
        safeNet.start("ply")
        safeNet.send(owner())
    end)
]]
else
    --Client
    local localEnv = class("localEnv")
    local localPlayer = class("localPlayer")
    function localPlayer:initialize()
        self.eliminated = false
        return self
    end
    function localEnv:initialize(localPlayer)
        self.localPlayer = localPlayer
        self.gamePlayerList = {}
        return self
    end
    
    local player = localPlayer:new()
    local env = localEnv:new(player)
    env.fonts = {
        eliminationFont = render.createFont("Roboto", 100, 10000, true, false, false, true, 4, false)
    }
    env.games = {}
    
    
    
    safeNet.receive("elimination", function()
        player.eliminated = true
        print("elim")
    end)
    
    safeNet.receive("gameplylist", function()
        local gameName = safeNet.readString()
        env.games[gameName] = safeNet.readTable()
        printTable(env.games[gameName])
    end)
    
    hook.add("drawhud", "swervehud", function()
        local w, h = render.getResolution()
        -- Elimination effects
        if player.eliminated then
            render.setFont(env.fonts.eliminationFont)
            render.drawText(w * 0.5, 100, "Eliminated!", 1)
            
        end
    end)
end
