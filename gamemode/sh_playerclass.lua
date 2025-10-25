SS = SS or {}
SS.Loadouts = SS.Loadouts or {}



-------------------------------------------------
-- Team loadouts (TFA-only weapons verified)
-------------------------------------------------
SS.Loadouts[TEAM_COLLECT] = {
    Fixed = {
        "tfa_yonglicustom_matelbat",  -- melee
        "tfa_ins2_wpn_m1911colt"      -- pistol
    },
    Random = {
        "tfa_ins2_wpn_coltm4a1",      -- rifle
        "tfa_ins2_wpn_hkump45",       -- SMG
        "tfa_ins2_wpn_mk18cqbr",      -- carbine
        "tfa_ins2_wpn_m40a1",         -- sniper
        "tfa_ins2_wpn_m45a1",         -- pistol variant
        "tfa_ins2_wpn_rpg7"           -- heavy
    }
}

SS.Loadouts[TEAM_DEFEND] = {
    Fixed = {
        "tfa_melee_stunstick",        -- melee
        "tfa_ins2_wpn_berettam9"      -- sidearm
    },
    Random = {
        "tfa_ins2_wpn_imigalilsar",   -- galil SAR
        "tfa_ins2_wpn_ak74izh",       -- assault rifle
        "tfa_ins2_wpn_sksimonov",     -- semi-auto rifle
        "tfa_ins2_wpn_l1a1",          -- battle rifle
        "tfa_ins2_wpn_at4"            -- heavy launcher
    }
}

