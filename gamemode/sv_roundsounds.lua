-- ===============================================
-- Slender Siege Round Sound System
-- ===============================================
if not SERVER then return end

-- Precache and add sound files for clients
local sounds = {
    "slendersiege/goodluck.wav",
    "slendersiege/entity_is_lurking.wav",
    "slendersiege/1collector.wav",
    "slendersiege/1defender.wav",
    "slendersiege/collectorswin.wav",
    "slendersiege/defenderswin.wav"
}

for _, snd in ipairs(sounds) do
    resource.AddFile("sound/" .. snd)
    util.PrecacheSound(snd)
end

-- Utility: Play a sound for all players
local function PlayRoundSound(soundPath)
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply:SendLua("surface.PlaySound('" .. soundPath .. "')")
        end
    end
end

-- ===============================
-- EVENT HOOKS
-- ===============================

-- Play at round start
hook.Add("SS_BeginRound", "SS_PlayRoundStartSound", function()
    timer.Simple(1.5, function()
        PlayRoundSound("slendersiege/goodluck.wav")
    end)
end)

-- Play when SlenderBot spawns
hook.Add("SS_SlenderSpawned", "SS_EntityLurkingSound", function()
    PlayRoundSound("slendersiege/entity_is_lurking.wav")
end)

-- Track single-player left states
SS.OneCollectorPlayed = false
SS.OneDefenderPlayed = false

hook.Add("Think", "SS_CheckOnePlayerLeftAudio", function()
    if SS.State ~= SS.ROUND_STATE.LIVE then return end

    local collectors, defenders = {}, {}

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then
            if ply:Team() == TEAM_COLLECT then
                table.insert(collectors, ply)
            elseif ply:Team() == TEAM_DEFEND then
                table.insert(defenders, ply)
            end
        end
    end

    -- One Collector left
    if #collectors == 1 and not SS.OneCollectorPlayed then
        SS.OneCollectorPlayed = true
        PlayRoundSound("slendersiege/1collector.wav")
    elseif #collectors > 1 then
        SS.OneCollectorPlayed = false
    end

    -- One Defender left
    if #defenders == 1 and not SS.OneDefenderPlayed then
        SS.OneDefenderPlayed = true
        PlayRoundSound("slendersiege/1defender.wav")
    elseif #defenders > 1 then
        SS.OneDefenderPlayed = false
    end
end)

-- Win sounds
hook.Add("SS_EndRound", "SS_PlayWinSounds", function(winnerTeam)
    timer.Simple(2, function()
        if winnerTeam == TEAM_COLLECT then
            PlayRoundSound("slendersiege/collectorswin.wav")
        elseif winnerTeam == TEAM_DEFEND then
            PlayRoundSound("slendersiege/defenderswin.wav")
        end
    end)
end)

print("[SS] Round sound system initialized.")

