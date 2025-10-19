SS = SS or {}
SS.State = SS.ROUND_STATE and SS.ROUND_STATE.WAIT or "wait"
SS.RoundEndTime = 0
SS.PageCount = 0

function SS:GetTargetPages() return GetConVar("ss_target_pages"):GetInt() end
function SS:PagesRemaining() return math.max(self:GetTargetPages() - (SS.PageCount or 0), 0) end

-- ConVars
CreateConVar("ss_target_pages", "20", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Pages needed to win for Collectors", 1, 100)
CreateConVar("ss_round_time", "600", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Round length in seconds", 60, 3600)
CreateConVar("ss_fill_bots", "1", FCVAR_ARCHIVE, "Auto add bots up to 4 total")
