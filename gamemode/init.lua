AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_stealth.lua")
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
    
    -- Make it very visible
    self:SetModelScale(2, 0) -- Much bigger
    self:SetColor(Color(255, 255, 0, 255)) -- Bright yellow
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    
    -- Physics
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then 
        phys:EnableMotion(false)
        phys:Wake()
    end
    
    self.BobOffset = math.random() * 360
    self.StartPos = self:GetPos()
    
    -- Create a visible sprite effect
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

function GM:Initialize()
  SS.State = SS.ROUND_STATE.WAIT
  SS.RoundEndTime = 0
  SS.PageCount = 0
end

-- Team assignment is handled in sv_teamlogic.lua
function GM:PlayerInitialSpawn(ply)
  -- Let the hook in sv_teamlogic.lua handle team assignment
  player_manager.SetPlayerClass(ply, "player_slendersiege")
end

function GM:PlayerSpawn(ply)
  player_manager.OnPlayerSpawn(ply)
  player_manager.RunClass(ply, "SetModel")
  ply:SetupHands()
  player_manager.RunClass(ply, "Loadout")
  ply:SetNWBool("SS_Hidden", false)
end

local function SS_BeginRound()
  if SS.State == SS.ROUND_STATE.LIVE then return end
  SS.State = SS.ROUND_STATE.LIVE
  SS.RoundEndTime = CurTime() + GetConVar("ss_round_time"):GetInt()
  SS.PageCount = 0

  -- spawn pages
  for _,e in ipairs(ents.FindByClass("slender_page")) do e:Remove() end
  local count = GetConVar("ss_target_pages"):GetInt() -- Spawn exact number needed
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
  
  -- Broadcast initial page count
  net.Start("SS_PageCount")
    net.WriteUInt(0, 8)
    net.WriteUInt(count, 8)
  net.Broadcast()

  if #ents.FindByClass("npc_slender") == 0 then
    local sl = ents.Create("npc_slender")
    if IsValid(sl) then sl:Spawn() end
  end
end

local function SS_EndRound(winnerTeam, reason)
  if SS.State ~= SS.ROUND_STATE.LIVE then return end
  SS.State = SS.ROUND_STATE.POST
  PrintMessage(HUD_PRINTTALK, ("[Round Over] %s win! (%s)"):format(team.GetName(winnerTeam) or "Unknown", reason or ""))
  timer.Simple(8, function()
    SS.State = SS.ROUND_STATE.WAIT
    SS_BeginRound()
  end)
end

function GM:Think()
  if SS.State == SS.ROUND_STATE.WAIT then
    if player.GetCount() >= 1 then SS_BeginRound() end
  elseif SS.State == SS.ROUND_STATE.LIVE then
    if CurTime() >= (SS.RoundEndTime or 0) then
      SS_EndRound(TEAM_DEFEND, "Time expired")
    elseif SS.PageCount >= SS:GetTargetPages() then
      SS_EndRound(TEAM_COLLECT, "All pages collected")
    end
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
    if GetConVar("ss_fill_bots"):GetBool() then
      local want = 4
      local have = player.GetCount()
      if have < want then game.AddBots(want - have) end
    end
  end)
end

-- Receive hidden state from clients so teammates can see hidden allies
net.Receive("SS_HiddenPing", function(_, ply)
  if not IsValid(ply) then return end
  local hidden = net.ReadBool()
  ply:SetNWBool("SS_Hidden", hidden)
end)

-- Debug command to check teams
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
    print(string.format("  %s - Team %d (%s) - Color: %s", 
      p:Nick(), p:Team(), team.GetName(p:Team()), tostring(team.GetColor(p:Team()))))
  end
  print("==================\n")
end)

-- Debug: Manually spawn a test page
concommand.Add("ss_spawnpage", function(ply)
  if not IsValid(ply) then return end
  
  local trace = ply:GetEyeTrace()
  local pos = trace.HitPos + Vector(0, 0, 16)
  
  local page = ents.Create("slender_page")
  if IsValid(page) then
    page:SetPos(pos)
    page:Spawn()
    print("[SS] Manually spawned page at: " .. tostring(pos))
    ply:ChatPrint("Spawned page at your crosshair!")
  else
    print("[SS ERROR] Failed to create slender_page entity!")
    ply:ChatPrint("ERROR: Could not create page entity!")
  end
end)

-- Debug: Count existing pages
concommand.Add("ss_countpages", function(ply)
  local pages = ents.FindByClass("slender_page")
  print("[SS] Found " .. #pages .. " pages on the map")
  if IsValid(ply) then
    ply:ChatPrint("Pages on map: " .. #pages)
  end
  for i, page in ipairs(pages) do
    print("  Page " .. i .. ": " .. tostring(page:GetPos()))
  end
end)

-- Debug: Teleport to first page
concommand.Add("ss_gotopage", function(ply)
  if not IsValid(ply) then return end
  local pages = ents.FindByClass("slender_page")
  if #pages > 0 then
    ply:SetPos(pages[1]:GetPos() + Vector(0, 0, 50))
    ply:ChatPrint("Teleported to page!")
    print("[SS] Teleported " .. ply:Nick() .. " to page at " .. tostring(pages[1]:GetPos()))
  else
    ply:ChatPrint("No pages found!")
  end
end)
