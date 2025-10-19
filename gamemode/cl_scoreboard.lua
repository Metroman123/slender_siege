-- Override scoreboard team colors
hook.Add("Initialize", "SS_ScoreboardColors", function()
    -- Force scoreboard to use our colors
    timer.Simple(1, function()
        team.SetUp(1, "Collectors", Color(190,190,255), true)
        team.SetUp(2, "Defenders", Color(180,255,180), false)
    end)
end)

-- Override the team color getter for scoreboard
local oldGetColor = team.GetColor
function team.GetColor(teamid)
    if teamid == 1 then
        return Color(190, 190, 255)
    elseif teamid == 2 then
        return Color(180, 255, 180)
    end
    return oldGetColor(teamid)
end
