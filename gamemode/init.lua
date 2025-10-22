-- Team-specific spawn point selection
function GM:PlayerSelectTeamSpawn(teamid, ply)
    local spawnClass = "info_player_start" -- Fallback
    
    if teamid == TEAM_COLLECT then
        spawnClass = "info_collector_spawn"
    elseif teamid == TEAM_DEFEND then
        spawnClass = "info_defender_spawn"
    end
    
    local spawns = ents.FindByClass(spawnClass)
    
    -- Fallback to generic spawns if team spawns don't exist
    if #spawns == 0 then
        spawns = ents.FindByClass("info_player_start")
    end
    
    if #spawns > 0 then
        return spawns[math.random(#spawns)]
    end
    
    return nil
end

-- Distribute client files
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_stealth.lua")
AddCSLuaFile("cl_teamselect.lua")

-- Mount the Workshop addons containing our custom playermodels.  These
-- calls run only on the server and make sure that clients download
-- the workshop content before joining.  Replace the placeholder IDs
-- with the actual workshop IDs for your playermodel addons.
if SERVER then
    -- list the Workshop IDs you want to download
    local workshopIDs = {
        "3544841475", -- gm_everpine night and sunset map (example)
        "123456789",  -- Chaos Insurgency Trooper player model
        "987654321",  -- Nine-Tailed Fox Operative player model
        "183701075",
        "2840031720",
        "3478998917",
        "2840032487",
        "3250080642",
        "1345220508",
        "112806637",
        "3258287434",
        "2418786292",
        "3457033901",
        "112806637",
        "2625892196",
        "3442282370",
        
    }
end
include("shared.lua")

--==============================================
-- REGISTER SLENDER_PAGE ENTITY INLINE
--==============================================
local ENT = {}
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Slender Page"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:Initialize()
    self:SetModel("models/hunter/plates/plate.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self:SetUseType(SIMPLE_USE)
    
    self:SetModelScale(2, 0)
    self:SetColor(Color(255, 255, 0, 255))
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then 
        phys:EnableMotion(false)
        phys:Wake()
    end
    
    self.BobOffset = math.random() * 360
    self.StartPos = self:GetPos()
    self:SetNWVector("PagePos", self:GetPos())
    
    print("[SS] Page spawned at: " .. tostring(self:GetPos()))
end

function ENT:Think()
    if self.StartPos then
        local bob = math.sin(CurTime() * 2 + self.BobOffset) * 8
        self:SetPos(self.StartPos + Vector(0, 0, bob))
    end
    self:SetAngles(Angle(0, CurTime() * 30, 0))
    self:NextThink(CurTime() + 0.05)
    return true
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if activator:Team() ~= TEAM_COLLECT then
        activator:ChatPrint("Only Collectors can pick up pages!")
        return
    end
    self:EmitSound("items/battery_pickup.wav", 75, 100)
    PrintMessage(HUD_PRINTTALK, activator:Nick() .. " collected a page!")
    hook.Run("SS_PageCollected", activator, self)
    self:Remove()
end

scripted_ents.Register(ENT, "slender_page")
print("[SS] Registered slender_page entity!")

--==============================================
-- Team Logic
--==============================================
include("sv_teamlogic.lua")
include("sv_voice.lua")

function GM:Initialize()
  SS.State = SS.ROUND_STATE.TEAM_SELECT
  SS.RoundEndTime = 0
  SS.PageCount = 0
  SS.TeamSelectEndTime = 0
  print("[SS] Gamemode initialized - Starting in TEAM_SELECT state")
end

function GM:PlayerInitialSpawn(ply)
  player_manager.SetPlayerClass(ply, "player_slendersiege")
  
  -- Store their chosen team
  ply:SetNWInt("SS_ActualTeam", ply:Team())
  
  -- Don't auto-assign teams during team select
  if SS.State ~= SS.ROUND_STATE.TEAM_SELECT then
    -- Let sv_teamlogic handle assignment
    return
  end
  
  -- If in team select, show the menu after a delay
  if SS.TeamSelectEndTime > 0 then
    timer.Simple(0.5, function()
      if IsValid(ply) then
        net.Start("SS_ShowTeamSelect")
          net.WriteBool(true)
          net.WriteFloat(SS.TeamSelectEndTime)
        net.Send(ply)
        print("[SS] Showed team select to " .. ply:Nick())
      end
    end)
  end
end

-- Handle player death - move to spectator
function GM:PlayerDeath(ply, inflictor, attacker)
  if SS.State == SS.ROUND_STATE.LIVE then
    -- Store their actual team
    ply:SetNWInt("SS_ActualTeam", ply:Team())
    
    -- Move to spectator
    timer.Simple(2, function()
      if IsValid(ply) then
        ply:SetTeam(TEAM_SPECTATOR)
        ply:Spawn()
      end
    end)
  end
end

-- Prevent dead players from spawning until next round
function GM:PlayerDeathThink(ply)
  if SS.State == SS.ROUND_STATE.LIVE and ply:Team() == TEAM_SPECTATOR then
    return false -- Don't allow respawn
  end
  return true
end

function GM:PlayerSpawn(ply)
  -- Store their actual team before spawning
  local actualTeam = ply:GetNWInt("SS_ActualTeam", ply:Team())
  
  -- If they're dead during a live round, make them spectate
  if SS.State == SS.ROUND_STATE.LIVE and ply:Team() == TEAM_SPECTATOR then
    ply:StripWeapons()
    ply:SetNoTarget(true)
    ply:SetNoDraw(true)
    ply:SetMoveType(MOVETYPE_NOCLIP)
    ply:DrawWorldModel(false)
    ply:Spectate(OBS_MODE_ROAMING)
    ply:ChatPrint("You are spectating. Wait for next round.")
    return
  end
  
  -- Initialize player class handling. This will invoke the appropriate
  -- PlayerSpawn function from the player's class but does not set
  -- the model; we handle that manually below to avoid recursive
  -- SetModel calls.
  player_manager.OnPlayerSpawn(ply)

  -- Assign a team-specific model if the player has chosen a team.
  -- We only override the model for Collectors or Defenders.  For
  -- unassigned or spectator players, we leave the model alone so
  -- their personal playermodel or default choice is used.  The model
  -- lists are defined in sh_config.lua and must be populated with
  -- valid paths.  Randomly select a model from the team list.
  do
    local t = ply:Team()
    local models
    if t == TEAM_COLLECT then
      models = SS.PlayerModels and SS.PlayerModels.collector
    elseif t == TEAM_DEFEND then
      models = SS.PlayerModels and SS.PlayerModels.defender
    end
    if models and istable(models) and #models > 0 then
      local mdl = models[math.random(#models)]
      -- Use Entity.SetModel directly to bypass player_manager recursion
      local entMeta = FindMetaTable("Entity")
      if entMeta and entMeta.SetModel then
        entMeta.SetModel(ply, mdl)
      else
        ply:SetModel(mdl)
      end
    end
  end

  -- Set up viewmodel hands after assigning the model (or leaving it
  -- unchanged).  Without this call the player's viewmodel arms may
  -- not match their model.
  ply:SetupHands()

  -- Give the player their loadout defined in sh_playerclass.lua
  player_manager.RunClass(ply, "Loadout")
  ply:SetNWBool("SS_Hidden", false)
  ply:SetNoTarget(false)
  ply:SetNoDraw(false)
  ply:UnSpectate()
  
  -- Team-specific spawns
  local spawnPoint = self:PlayerSelectTeamSpawn(ply:Team(), ply)
  if IsValid(spawnPoint) then
    ply:SetPos(spawnPoint:GetPos() + Vector(0, 0, 10))
  end
end

local function SS_BeginRound()
  if SS.State == SS.ROUND_STATE.LIVE then return end
  SS.State = SS.ROUND_STATE.LIVE
  SS.RoundEndTime = CurTime() + GetConVar("ss_round_time"):GetInt()
  SS.PageCount = 0

  print("[SS] Round starting!")
  
  -- Restore spectators to their actual teams and respawn everyone
  for _, ply in ipairs(player.GetAll()) do
    if IsValid(ply) then
      local actualTeam = ply:GetNWInt("SS_ActualTeam", ply:Team())
      if actualTeam == TEAM_COLLECT or actualTeam == TEAM_DEFEND then
        ply:SetTeam(actualTeam)
      end
      ply:Spawn()
    end
  end

  -- spawn pages
  for _,e in ipairs(ents.FindByClass("slender_page")) do e:Remove() end
  local count = GetConVar("ss_target_pages"):GetInt()
  local placed = 0
  
  print("[SS] Attempting to spawn " .. count .. " pages...")
  
  if navmesh and navmesh.GetAllNavAreas then
    local areas = navmesh.GetAllNavAreas()
    if areas and #areas > 0 then
      print("[SS] Using navmesh, found " .. #areas .. " areas")
      for i=1,count do
        local area = areas[math.random(#areas)]
        if IsValid(area) then
          local pos = area:GetRandomPoint()
          local e = ents.Create("slender_page")
          if IsValid(e) then 
            e:SetPos(pos + Vector(0,0,16)) 
            e:Spawn() 
            placed = placed + 1 
          end
        end
      end
    else
      print("[SS] No navmesh areas found!")
    end
  else
    print("[SS] No navmesh available!")
  end
  
  if placed < count then
    print("[SS] Navmesh only placed " .. placed .. " pages, filling remaining " .. (count - placed) .. " randomly...")
    for i=1,(count - placed) do
      local plys = player.GetAll()
      if #plys > 0 then
        local base = plys[math.random(#plys)]:GetPos()
        local e = ents.Create("slender_page")
        if IsValid(e) then 
          e:SetPos(base + VectorRand()*math.random(200,900) + Vector(0,0,16)) 
          e:Spawn() 
          placed = placed + 1
        end
      end
    end
  end
  
  print("[SS] Successfully spawned " .. placed .. " pages total")
  
  net.Start("SS_PageCount")
    net.WriteUInt(0, 8)
    net.WriteUInt(count, 8)
  net.Broadcast()

  -- TODO: Fix npc_slender entity before enabling
  --[[
  if #ents.FindByClass("npc_slender") == 0 then
    local sl = ents.Create("npc_slender")
    if IsValid(sl) then sl:Spawn() end
  end
  ]]--
end

local function SS_EndRound(winnerTeam, reason)
  if SS.State ~= SS.ROUND_STATE.LIVE then return end
  SS.State = SS.ROUND_STATE.POST
  
  -- Send round end to all clients
  net.Start("SS_RoundEnd")
    net.WriteUInt(winnerTeam, 8)
    net.WriteString(reason or "")
  net.Broadcast()
  
  print("[SS] Round Over: " .. team.GetName(winnerTeam) .. " win! (" .. reason .. ")")
  
  -- Clean up pages
  for _,e in ipairs(ents.FindByClass("slender_page")) do e:Remove() end
  
  timer.Simple(10, function()
    SS.State = SS.ROUND_STATE.TEAM_SELECT
    SS.TeamSelectEndTime = 0
    print("[SS] Returning to team select...")
  end)
end

function GM:Think()
  -- Wrap in pcall to catch errors
  local success, err = pcall(function()
    if SS.State == SS.ROUND_STATE.TEAM_SELECT then
      -- Start team select if not started
      if SS.TeamSelectEndTime == 0 and player.GetCount() >= 1 then
        SS.TeamSelectEndTime = CurTime() + GetConVar("ss_teamselect_time"):GetInt()
        
        -- Show team select to all players
        for _, ply in ipairs(player.GetAll()) do
          if IsValid(ply) then
            net.Start("SS_ShowTeamSelect")
              net.WriteBool(true)
              net.WriteFloat(SS.TeamSelectEndTime)
            net.Send(ply)
          end
        end
        
        print("[SS] Team selection started! Time: " .. GetConVar("ss_teamselect_time"):GetInt() .. "s")
      end
      
      -- Check if team select should end
      if SS.TeamSelectEndTime > 0 then
        local allSelected = true
        local humanPlayers = 0
        
        for _, ply in ipairs(player.GetAll()) do
          if IsValid(ply) and not ply:IsBot() then
            humanPlayers = humanPlayers + 1
            if ply:Team() ~= TEAM_COLLECT and ply:Team() ~= TEAM_DEFEND then
              allSelected = false
            end
          end
        end
        
        -- End team select if all selected or time expired
        if (allSelected and humanPlayers > 0) or CurTime() >= SS.TeamSelectEndTime then
          print("[SS] Ending team select - All selected: " .. tostring(allSelected) .. ", Time up: " .. tostring(CurTime() >= SS.TeamSelectEndTime))
          
          -- Hide team select menu
          for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) then
              net.Start("SS_ShowTeamSelect")
                net.WriteBool(false)
                net.WriteFloat(0)
              net.Send(ply)
            end
          end
          
          -- Assign remaining players to balance teams
          for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and (ply:Team() ~= TEAM_COLLECT and ply:Team() ~= TEAM_DEFEND) then
              local collectors = team.NumPlayers(TEAM_COLLECT)
              local defenders = team.NumPlayers(TEAM_DEFEND)
              ply:SetTeam(collectors <= defenders and TEAM_COLLECT or TEAM_DEFEND)
              print("[SS] Auto-assigned " .. ply:Nick() .. " to " .. team.GetName(ply:Team()))
            end
          end
          
          print("[SS] Team selection complete!")
          SS.State = SS.ROUND_STATE.WAIT
          SS.TeamSelectEndTime = 0
        end
      end
    elseif SS.State == SS.ROUND_STATE.WAIT then
      if player.GetCount() >= 1 then 
        SS_BeginRound() 
      end
    elseif SS.State == SS.ROUND_STATE.LIVE then
      -- Check win conditions
      
      -- 1. Time expired
      if CurTime() >= (SS.RoundEndTime or 0) then
        SS_EndRound(TEAM_DEFEND, "Time expired")
        
      -- 2. All pages collected
      elseif SS.PageCount >= SS:GetTargetPages() then
        SS_EndRound(TEAM_COLLECT, "All pages collected")
        
      -- 3. All collectors dead
      else
        local aliveCollectors = 0
        local aliveDefenders = 0
        
        for _, ply in ipairs(player.GetAll()) do
          if IsValid(ply) and ply:Alive() then
            if ply:Team() == TEAM_COLLECT then
              aliveCollectors = aliveCollectors + 1
            elseif ply:Team() == TEAM_DEFEND then
              aliveDefenders = aliveDefenders + 1
            end
          end
        end
        
        -- All collectors dead = Defenders win
        if aliveCollectors == 0 and team.NumPlayers(TEAM_COLLECT) > 0 then
          SS_EndRound(TEAM_DEFEND, "All collectors eliminated")
          
        -- All defenders dead = Collectors win (they can collect pages safely)
        elseif aliveDefenders == 0 and team.NumPlayers(TEAM_DEFEND) > 0 then
          SS_EndRound(TEAM_COLLECT, "All defenders eliminated")
        end
      end
    end
  end)
  
  if not success then
    print("[SS ERROR in GM:Think] " .. tostring(err))
  end
end

hook.Add("SS_PageCollected", "SS_UpdateCount", function(collector)
  SS.PageCount = (SS.PageCount or 0) + 1
  net.Start("SS_PageCount")
    net.WriteUInt(SS.PageCount, 8)
    net.WriteUInt(SS:GetTargetPages(), 8)
  net.Broadcast()
end)

local function SS_BroadcastRound()
  if SS.State ~= SS.ROUND_STATE.LIVE then return end
  net.Start("SS_RoundTimer")
    net.WriteFloat(math.max(0, (SS.RoundEndTime or 0) - CurTime()))
  net.Broadcast()
end
timer.Create("SS_RoundNet", 1, 0, SS_BroadcastRound)

-- Bot filler
if game and game.AddBots then
  timer.Create("SS_BotFiller", 5, 0, function()
    if GetConVar("ss_fill_bots"):GetBool() and SS.State ~= SS.ROUND_STATE.TEAM_SELECT then
      local want = 4
      local have = player.GetCount()
      if have < want then game.AddBots(want - have) end
    end
  end)
end

-- Receive hidden state from clients
net.Receive("SS_HiddenPing", function(_, ply)
  if not IsValid(ply) then return end
  local hidden = net.ReadBool()
  ply:SetNWBool("SS_Hidden", hidden)
end)

-- Handle team selection
net.Receive("SS_SelectTeam", function(_, ply)
  if not IsValid(ply) then return end
  if SS.State ~= SS.ROUND_STATE.TEAM_SELECT then 
    print("[SS] " .. ply:Nick() .. " tried to select team but not in team select state")
    return 
  end
  
  local teamid = net.ReadUInt(8)
  if teamid ~= TEAM_COLLECT and teamid ~= TEAM_DEFEND then return end
  
  ply:SetTeam(teamid)
  print("[SS] " .. ply:Nick() .. " selected " .. team.GetName(teamid))

  -- Immediately respawn the player with their new team so their model
  -- and loadout are updated.  We use KillSilent() to avoid death
  -- messages and then spawn them.  Without this, players keep their
  -- previous model until they die, which is confusing when switching
  -- teams.  Only do this if the player is alive; otherwise they
  -- will respawn on death anyway.
  if ply:Alive() then
    ply:KillSilent()
    -- Delay spawn slightly so the kill can process
    timer.Simple(0.1, function()
      if IsValid(ply) then ply:Spawn() end
    end)
  end
end)

-- Debug commands
concommand.Add("ss_checkteams", function(ply)
  print("\n=== TEAM DEBUG ===")
  print("TEAM_COLLECT = " .. TEAM_COLLECT)
  print("  Name: " .. team.GetName(TEAM_COLLECT))
  print("  Color: " .. tostring(team.GetColor(TEAM_COLLECT)))
  print("  Players: " .. team.NumPlayers(TEAM_COLLECT))
  
  print("\nTEAM_DEFEND = " .. TEAM_DEFEND)
  print("  Name: " .. team.GetName(TEAM_DEFEND))
  print("  Color: " .. tostring(team.GetColor(TEAM_DEFEND)))
  print("  Players: " .. team.NumPlayers(TEAM_DEFEND))
  
  print("\nAll Players:")
  for _, p in ipairs(player.GetAll()) do
    print(string.format("  %s - Team %d (%s)", 
      p:Nick(), p:Team(), team.GetName(p:Team())))
  end
  print("==================\n")
end)

concommand.Add("ss_spawnpage", function(ply)
  if not IsValid(ply) then return end
  local trace = ply:GetEyeTrace()
  local pos = trace.HitPos + Vector(0, 0, 16)
  local page = ents.Create("slender_page")
  if IsValid(page) then
    page:SetPos(pos)
    page:Spawn()
    print("[SS] Manually spawned page at: " .. tostring(pos))
    ply:ChatPrint("Spawned page!")
  end
end)

concommand.Add("ss_countpages", function(ply)
  local pages = ents.FindByClass("slender_page")
  print("[SS] Found " .. #pages .. " pages")
  if IsValid(ply) then ply:ChatPrint("Pages: " .. #pages) end
end)

concommand.Add("ss_gotopage", function(ply)
  if not IsValid(ply) then return end
  local pages = ents.FindByClass("slender_page")
  if #pages > 0 then
    ply:SetPos(pages[1]:GetPos() + Vector(0, 0, 50))
    ply:ChatPrint("Teleported!")
  end
end)

concommand.Add("ss_skipteamselect", function(ply)
  if SS.State == SS.ROUND_STATE.TEAM_SELECT then
    SS.TeamSelectEndTime = CurTime() - 1
    print("[SS] Skipping team select...")
  end
end)
