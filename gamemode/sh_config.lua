SS = SS or {}
SS.ROUND_STATE = { TEAM_SELECT="team_select", WAIT="wait", LIVE="live", POST="post" }
SS.State = SS.ROUND_STATE.TEAM_SELECT
SS.RoundEndTime = 0
SS.PageCount = 0
SS.TeamSelectEndTime = 0

function SS:GetTargetPages() return GetConVar("ss_target_pages"):GetInt() end
function SS:PagesRemaining() return math.max(self:GetTargetPages() - (SS.PageCount or 0), 0) end

-- ConVars
CreateConVar("ss_target_pages", "20", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Pages needed to win for Collectors", 1, 100)
CreateConVar("ss_round_time", "600", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Round length in seconds", 60, 3600)
CreateConVar("ss_teamselect_time", "30", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Team selection time in seconds", 10, 120)
CreateConVar("ss_fill_bots", "1", FCVAR_ARCHIVE, "Auto add bots up to 4 total")



-- sh_config.lua
SS.PlayerModels = SS.PlayerModels or {}
SS.PlayerModels.collector = {
    "models/stalker_mercgang/stalker_merc_2.mdl",-- replace with correct path
    "models/stalker_mercgang/stalker_ki_head_5.mdl",
    "models/stalker_mercgang/merc_meshanik.mdl",
    "models/stalker_mercgang/stalke_mercenary1_2.mdl",
}
SS.PlayerModels.defender = {
    "models/player/dpr_militia_heavy.mdl",
    "models/player/dpr_militia_light.mdl",
    "models/mfc_new.mdl",
    "models/mfc_new_heavy.mdl",
    
}

