-------------------------------------------------
-- TEAM LOGIC (SERVER-SIDE)
-------------------------------------------------

-- Force re-setup teams (in case sandbox overrode them)
timer.Simple(0, function()
    team.SetUp(TEAM_COLLECT, "Collectors", Color(190,190,255), true)
    team.SetUp(TEAM_DEFEND,  "Defenders",  Color(180,255,180), false)
    
    print("=== Teams Re-initialized ===")
    print("TEAM_COLLECT:", TEAM_COLLECT, team.GetName(TEAM_COLLECT), team.GetColor(TEAM_COLLECT))
    print("TEAM_DEFEND:", TEAM_DEFEND, team.GetName(TEAM_DEFEND), team.GetColor(TEAM_DEFEND))
end)

-- Override sandbox's team selection
hook.Add("PlayerInitialSpawn", "SS_AssignTeam", function(ply)
    -- Give it a moment for player to fully initialize
    timer.Simple(0.1, function()
        if not IsValid(ply) then return end
        
        local collectors = team.NumPlayers(TEAM_COLLECT)
        local defenders  = team.NumPlayers(TEAM_DEFEND)

        local assignTeam = TEAM_COLLECT
        if collectors > defenders then
            assignTeam = TEAM_DEFEND
        end
        
        ply:SetTeam(assignTeam)
        
        print(string.format("Player %s assigned to team %d (%s)", 
            ply:Nick(), assignTeam, team.GetName(assignTeam)))
    end)
end)

-- Prevent sandbox from changing teams
hook.Add("PlayerSpawn", "SS_LockTeam", function(ply)
    -- If on wrong team or unassigned, fix it
    local currentTeam = ply:Team()
    
    if currentTeam ~= TEAM_COLLECT and currentTeam ~= TEAM_DEFEND then
        local collectors = team.NumPlayers(TEAM_COLLECT)
        local defenders  = team.NumPlayers(TEAM_DEFEND)
        
        if collectors <= defenders then
            ply:SetTeam(TEAM_COLLECT)
        else
            ply:SetTeam(TEAM_DEFEND)
        end
        
        print(string.format("Fixed %s's team from %d to %d", 
            ply:Nick(), currentTeam, ply:Team()))
    end
end)

-- Block sandbox team changes
hook.Add("PlayerCanJoinTeam", "SS_BlockTeamChange", function(ply, teamid)
    -- Only allow our two teams
    if teamid ~= TEAM_COLLECT and teamid ~= TEAM_DEFEND then
        return false
    end
    return true
end)

-- Safe spawn positioning
hook.Add("PlayerSpawn", "SS_SafeSpawn", function(ply)
    timer.Simple(0, function()
        if not IsValid(ply) then return end
        
        local spawnpoints = ents.FindByClass("info_player_start")
        if #spawnpoints > 0 then
            local spawn = spawnpoints[math.random(#spawnpoints)]
            ply:SetPos(spawn:GetPos() + Vector(0, 0, 10))
        else
            ply:SetPos(Vector(0, 0, 100))
        end
    end)
end)
