-------------------------------------------------
-- PROXIMITY VOICE CHAT
-------------------------------------------------

-- Voice chat range
local VOICE_RANGE = 1000 -- units

-- Dead players can't talk to alive players
hook.Add("PlayerCanHearPlayersVoice", "SS_ProximityVoice", function(listener, talker)
    if not IsValid(listener) or not IsValid(talker) then return false end
    
    -- Dead players (spectators) can only talk to other dead players
    if talker:Team() == TEAM_SPECTATOR then
        if listener:Team() == TEAM_SPECTATOR then
            return true, false -- Can hear, not 3D
        else
            return false -- Alive can't hear dead
        end
    end
    
    -- Dead players can hear everyone
    if listener:Team() == TEAM_SPECTATOR then
        return true, false -- Can hear, not 3D
    end
    
    -- Both alive - check proximity
    local dist = listener:GetPos():Distance(talker:GetPos())
    
    if dist <= VOICE_RANGE then
        -- Within range - use 3D positional audio
        return true, true
    else
        -- Out of range
        return false
    end
end)

-- Mute dead players' regular chat too (optional)
hook.Add("PlayerCanSeePlayersChat", "SS_DeadChatFilter", function(text, teamOnly, listener, talker)
    if not IsValid(listener) or not IsValid(talker) then return end
    
    -- Dead can only chat with dead
    if talker:Team() == TEAM_SPECTATOR and listener:Team() ~= TEAM_SPECTATOR then
        return false
    end
    
    return true
end)
