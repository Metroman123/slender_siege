GM.Name        = "Slender Siege"
GM.Author      = "Nicholas Morin"
GM.Email       = ""
GM.Website     = ""
GM.TeamBased   = true
GM.UseHands    = true

DeriveGamemode("sandbox")

-- IMPORTANT: Clear any existing teams first
if SERVER then
    -- Clear default sandbox teams
    for i = 1, 10 do
        team.SetUp(i, "", Color(0,0,0), false)
    end
end

-- Define our custom teams
TEAM_COLLECT  = 1
TEAM_DEFEND   = 2
TEAM_SPECTATOR = 1001

-- Force our team setup (do this multiple times to override sandbox)
team.SetUp(TEAM_COLLECT, "Collectors", Color(190,190,255), true)
team.SetUp(TEAM_DEFEND,  "Defenders",  Color(180,255,180), false)
team.SetUp(TEAM_SPECTATOR, "Spectators", Color(100,100,100), false)

-- Set spawn points for each team
function GM:PlayerSelectTeamSpawn(teamid, ply)
    local spawns = ents.FindByClass("info_player_start")
    if #spawns > 0 then
        return spawns[math.random(#spawns)]
    end
    return nil
end

-- Net channels
if SERVER then
  util.AddNetworkString("SS_PageCount")
  util.AddNetworkString("SS_RoundTimer")
  util.AddNetworkString("SS_HiddenPing")
  util.AddNetworkString("SS_ShowTeamSelect")
  util.AddNetworkString("SS_SelectTeam")
  util.AddNetworkString("SS_RoundEnd")
end

-- Include / Distribute
AddCSLuaFile()
AddCSLuaFile("sh_config.lua")
AddCSLuaFile("sh_round.lua")
AddCSLuaFile("sh_playerclass.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_teamselect.lua")
AddCSLuaFile("sh_stealth.lua")
AddCSLuaFile("cl_stealth.lua")
AddCSLuaFile("cl_topbar.lua")

include("sh_config.lua")
include("sh_round.lua")
include("sh_playerclass.lua")
include("sh_stealth.lua")

-- Hands model helper
local HANDS = {
  ["models/player/kleiner.mdl"] = {model="models/weapons/c_arms_citizen.mdl", skin=0, body=0},
  ["models/player/alyx.mdl"]    = {model="models/weapons/c_arms_alyx.mdl",    skin=0, body=0},
}
function GM:PlayerSetHandsModel(ply, ent)
  local mdl = string.lower(ply:GetModel() or "")
  local h = HANDS[mdl] or {model="models/weapons/c_arms_citizen.mdl", skin=0, body=0}
  ent:SetModel(h.model) ent:SetSkin(h.skin) ent:SetBodyGroups(h.body)
end

-- Debug: Print team info
if SERVER then
    print("=== SLENDER SIEGE TEAM SETUP ===")
    print("Team 1 (COLLECT):", team.GetName(TEAM_COLLECT), team.GetColor(TEAM_COLLECT))
    print("Team 2 (DEFEND):", team.GetName(TEAM_DEFEND), team.GetColor(TEAM_DEFEND))
end

function GM:PlayerSpawn(ply)
    player_manager.SetPlayerClass(ply, "player_default")
    ply:SetupHands()  -- ✅ this enables c_hands for the player
end

