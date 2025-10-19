-------------------------------------------------
-- Force correct team names after respawn
-------------------------------------------------
hook.Add("PlayerLoadout", "SS_EnsureTeamConsistency", function(ply)
    -- If player somehow got default team 0, reassign them
    if ply:Team() == 0 or not team.GetName(ply:Team()) then
        local collectors = team.NumPlayers(TEAM_COLLECT)
        local defenders  = team.NumPlayers(TEAM_DEFEND)

        if collectors <= defenders then
            ply:SetTeam(TEAM_COLLECT)
        else
            ply:SetTeam(TEAM_DEFEND)
        end
    end

    -- Safety: make sure team color/name stays correct
    local teamName = team.GetName(ply:Team())
    if not teamName or teamName == "" then
        ply:SetTeam(TEAM_COLLECT)
    end
end)




player_manager.RegisterClass("player_slendersiege", {
  DisplayName   = "Slender Siege Default",
  WalkSpeed     = 200,
  RunSpeed      = 320,
  DuckSpeed     = 0.3,
  UnDuckSpeed   = 0.3,
  CrouchedWalkSpeed = 0.4,
  JumpPower     = 180,
  CanUseFlashlight = true,
  AvoidPlayers  = true,
  TeammateNoCollide = true,

  Loadout = function(ply)
    if not IsValid(ply) then return end
    ply:StripWeapons()
    local t = ply:Team()
    local list = (t == TEAM_COLLECT) and SS.Loadout.collector or SS.Loadout.defender
    for _,wep in ipairs(list) do ply:Give(wep) end
  end,

  SetModel = function(ply)
    ply:SetModel("models/player/kleiner.mdl")
  end
}, "player_default")
