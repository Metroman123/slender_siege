-- ==============================================================
--  Slender Siege: Team Loadout System (fixed and cleaned)
-- ==============================================================

SS = SS or {}
SS.Loadouts = SS.Loadouts or {}

-- Use the correct constants TEAM_COLLECT and TEAM_DEFEND
SS.Loadouts[TEAM_COLLECT] = {
    Fixed = {
        "tfa_ins2_wpn_m1911colt",      -- always given
        "tfa_ins2_wpn_makarovpistol",
        "tfa_melee_crowbar"
    },
    Random = {
        "tfa_ins2_wpn_imigalilsar",
        "tfa_ins2_wpn_hkump45",
        "tfa_ins2_wpn_m45a1",
        "tfa_ins2_wpn_coltm4a1",
        "tfa_ins2_wpn_mossberg590"
    }
}

SS.Loadouts[TEAM_DEFEND] = {
    Fixed = {
        "tfa_ins2_wpn_berettam9",      -- always given
        "tfa_melee_pipe"
    },
    Random = {
        "tfa_ins2_wpn_m40a1",
        "tfa_ins2_wpn_sksimonov",
        "tfa_ins2_wpn_ak74izh",
        "tfa_ins2_wpn_l1a1",
        "tfa_ins2_wpn_hkmp5kpdw"
    }
}

-- ==============================================================
--  Helper: Give weapons safely (no missing class crash)
-- ==============================================================

local function SafeGive(ply, wep)
    if weapons.GetStored(wep) then
        ply:Give(wep)
    else
        print("[SS Loadouts] Missing weapon: " .. wep)
    end
end

-- ==============================================================
--  Give loadout on spawn
-- ==============================================================

hook.Add("PlayerSpawn", "SS_GiveTeamLoadout", function(ply)
    if not IsValid(ply) or not ply:Alive() then return end

    local teamID = ply:Team()
    local loadout = SS.Loadouts[teamID]
    if not loadout then return end

    timer.Simple(0.25, function()
        if not IsValid(ply) then return end

        ply:StripWeapons()

        -- Give fixed weapons
        for _, wep in ipairs(loadout.Fixed or {}) do
            SafeGive(ply, wep)
        end

        -- Give one random weapon
        if loadout.Random and #loadout.Random > 0 then
            SafeGive(ply, table.Random(loadout.Random))
        end

        -- Default ammo
        ply:GiveAmmo(60, "SMG1", true)
        ply:GiveAmmo(30, "Buckshot", true)
    end)
end)

-- ==============================================================
--  Universal ammo drops every 2 minutes
-- ==============================================================

timer.Create("SS_UniversalAmmo", 120, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then
            ply:GiveAmmo(10, "SMG1", true)
            ply:GiveAmmo(5, "Buckshot", true)
        end
    end
end)

