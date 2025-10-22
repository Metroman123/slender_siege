SS = SS or {}
SS.ShowTeamSelect = false
SS.TeamSelectEndTime = 0
SS.ShowRoundEnd = false
SS.RoundEndTeam = 0
SS.RoundEndReason = ""
SS.RoundEndTime = 0

-- Network message to show/hide team select
net.Receive("SS_ShowTeamSelect", function()
    SS.ShowTeamSelect = net.ReadBool()
    SS.TeamSelectEndTime = net.ReadFloat()
    print("[SS CLIENT] Team select menu: " .. tostring(SS.ShowTeamSelect))
    
    -- Enable/disable mouse cursor
    if SS.ShowTeamSelect then
        gui.EnableScreenClicker(true)
    else
        gui.EnableScreenClicker(false)
    end
end)

-- Network message for round end
net.Receive("SS_RoundEnd", function()
    SS.ShowRoundEnd = true
    SS.RoundEndTeam = net.ReadUInt(8)
    SS.RoundEndReason = net.ReadString()
    SS.RoundEndTime = CurTime() + 10
    
    -- Disable cursor during round end
    gui.EnableScreenClicker(false)
    
    print("[SS CLIENT] Round ended - " .. team.GetName(SS.RoundEndTeam) .. " win!")
    
    -- Hide after 10 seconds
    timer.Simple(10, function()
        SS.ShowRoundEnd = false
    end)
end)

-- Stylish team selection menu
hook.Add("HUDPaint", "SS_TeamSelectMenu", function()
    if not SS.ShowTeamSelect then return end
    
    local w, h = ScrW(), ScrH()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    -- Dark overlay
    surface.SetDrawColor(0, 0, 0, 240)
    surface.DrawRect(0, 0, w, h)
    
    -- Title
    draw.SimpleText("SLENDER SIEGE", "DermaLarge", w/2, 80, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("SELECT YOUR TEAM", "DermaDefault", w/2, 120, Color(200, 200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Timer
    local timeLeft = math.max(0, SS.TeamSelectEndTime - CurTime())
    local timerText = string.format("Time remaining: %d seconds", math.ceil(timeLeft))
    draw.SimpleText(timerText, "DermaDefault", w/2, 160, Color(255, 220, 170, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Team boxes
    local boxW, boxH = 400, 300
    local spacing = 100
    local startX = (w - (boxW * 2 + spacing)) / 2
    local startY = 220
    
    -- Check if player has selected a team
    local currentTeam = ply:Team()
    local hasSelected = (currentTeam == TEAM_COLLECT or currentTeam == TEAM_DEFEND)
    
    -- Collectors Box (Left)
    local collectorX = startX
    local collectorColor = Color(190, 190, 255, 200)
    local collectorHover = gui.MouseX() > collectorX and gui.MouseX() < collectorX + boxW and 
                          gui.MouseY() > startY and gui.MouseY() < startY + boxH
    
    if collectorHover then
        collectorColor = Color(210, 210, 255, 255)
    end
    if currentTeam == TEAM_COLLECT then
        collectorColor = Color(150, 255, 150, 255) -- Green if selected
    end
    
    -- Draw collector box
    draw.RoundedBox(8, collectorX, startY, boxW, boxH, collectorColor)
    draw.RoundedBox(8, collectorX + 4, startY + 4, boxW - 8, boxH - 8, Color(20, 20, 40, 220))
    
    -- Collector content
    draw.SimpleText("COLLECTORS", "DermaLarge", collectorX + boxW/2, startY + 40, Color(190, 190, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    local collectorDesc = {
        "• Collect 20 pages to win",
        "• Use stealth to hide from Slender",
        "• Work together with your team",
        "• Armed with basic weapons",
    }
    
    for i, line in ipairs(collectorDesc) do
        draw.SimpleText(line, "DermaDefault", collectorX + boxW/2, startY + 100 + (i * 25), Color(200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Player count
    local collectorCount = team.NumPlayers(TEAM_COLLECT)
    draw.SimpleText("Players: " .. collectorCount, "DermaDefault", collectorX + boxW/2, startY + boxH - 40, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    if not hasSelected then
        draw.SimpleText("CLICK TO JOIN", "DermaDefault", collectorX + boxW/2, startY + boxH - 20, Color(255, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    elseif currentTeam == TEAM_COLLECT then
        draw.SimpleText("✓ SELECTED", "DermaDefault", collectorX + boxW/2, startY + boxH - 20, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Defenders Box (Right)
    local defenderX = startX + boxW + spacing
    local defenderColor = Color(180, 255, 180, 200)
    local defenderHover = gui.MouseX() > defenderX and gui.MouseX() < defenderX + boxW and 
                         gui.MouseY() > startY and gui.MouseY() < startY + boxH
    
    if defenderHover then
        defenderColor = Color(200, 255, 200, 255)
    end
    if currentTeam == TEAM_DEFEND then
        defenderColor = Color(150, 255, 150, 255) -- Green if selected
    end
    
    -- Draw defender box
    draw.RoundedBox(8, defenderX, startY, boxW, boxH, defenderColor)
    draw.RoundedBox(8, defenderX + 4, startY + 4, boxW - 8, boxH - 8, Color(20, 40, 20, 220))
    
    -- Defender content
    draw.SimpleText("DEFENDERS", "DermaLarge", defenderX + boxW/2, startY + 40, Color(180, 255, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    local defenderDesc = {
        "• Prevent collectors from winning",
        "• Hunt down the collectors",
        "• Better weapons & equipment",
        "• Work with Slender (indirectly)",
    }
    
    for i, line in ipairs(defenderDesc) do
        draw.SimpleText(line, "DermaDefault", defenderX + boxW/2, startY + 100 + (i * 25), Color(200, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Player count
    local defenderCount = team.NumPlayers(TEAM_DEFEND)
    draw.SimpleText("Players: " .. defenderCount, "DermaDefault", defenderX + boxW/2, startY + boxH - 40, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    if not hasSelected then
        draw.SimpleText("CLICK TO JOIN", "DermaDefault", defenderX + boxW/2, startY + boxH - 20, Color(255, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    elseif currentTeam == TEAM_DEFEND then
        draw.SimpleText("✓ SELECTED", "DermaDefault", defenderX + boxW/2, startY + boxH - 20, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Bottom instruction
    if hasSelected then
        draw.SimpleText("Waiting for other players...", "DermaDefault", w/2, h - 60, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

-------------------------------------------------
-- ROUND END SCREEN
-------------------------------------------------
hook.Add("HUDPaint", "SS_RoundEndScreen", function()
    if not SS.ShowRoundEnd then return end
    
    local w, h = ScrW(), ScrH()
    
    -- Dark overlay with fade
    local alpha = 240
    local timeLeft = SS.RoundEndTime - CurTime()
    if timeLeft < 1 then
        alpha = math.max(0, 240 * timeLeft)
    end
    
    surface.SetDrawColor(0, 0, 0, alpha)
    surface.DrawRect(0, 0, w, h)
    
    -- Get winner team color
    local teamColor = team.GetColor(SS.RoundEndTeam) or Color(255, 255, 255)
    local teamName = team.GetName(SS.RoundEndTeam) or "Unknown"
    
    -- Pulsing effect
    local pulse = math.abs(math.sin(CurTime() * 2)) * 0.3 + 0.7
    
    -- Big winner announcement
    draw.SimpleText(string.upper(teamName), "DermaLarge", w/2, h/2 - 100, 
        Color(teamColor.r * pulse, teamColor.g * pulse, teamColor.b * pulse, alpha), 
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    draw.SimpleText("VICTORY!", "DermaLarge", w/2, h/2 - 40, 
        Color(255, 255, 255, alpha), 
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Reason
    draw.SimpleText(SS.RoundEndReason, "DermaDefault", w/2, h/2 + 20, 
        Color(200, 200, 200, alpha), 
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Countdown
    local countdown = math.ceil(timeLeft)
    if countdown > 0 then
        draw.SimpleText("Next round in: " .. countdown, "DermaDefault", w/2, h/2 + 80, 
            Color(255, 220, 170, alpha), 
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Decorative lines
    surface.SetDrawColor(teamColor.r, teamColor.g, teamColor.b, alpha * 0.5)
    surface.DrawRect(w/2 - 300, h/2 - 120, 600, 2)
    surface.DrawRect(w/2 - 300, h/2 + 100, 600, 2)
end)

-- Click handling
hook.Add("GUIMousePressed", "SS_TeamSelectClick", function(mouseCode)
    if not SS.ShowTeamSelect then return end
    if mouseCode ~= MOUSE_LEFT then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    -- Check if already selected
    local currentTeam = ply:Team()
    if currentTeam == TEAM_COLLECT or currentTeam == TEAM_DEFEND then return end
    
    local w, h = ScrW(), ScrH()
    local boxW, boxH = 400, 300
    local spacing = 100
    local startX = (w - (boxW * 2 + spacing)) / 2
    local startY = 220
    
    local mx, my = gui.MouseX(), gui.MouseY()
    
    -- Check collector box
    local collectorX = startX
    if mx > collectorX and mx < collectorX + boxW and my > startY and my < startY + boxH then
        net.Start("SS_SelectTeam")
            net.WriteUInt(TEAM_COLLECT, 8)
        net.SendToServer()
        surface.PlaySound("buttons/button14.wav")
        print("[SS CLIENT] Selected Collectors")
        return
    end
    
    -- Check defender box
    local defenderX = startX + boxW + spacing
    if mx > defenderX and mx < defenderX + boxW and my > startY and my < startY + boxH then
        net.Start("SS_SelectTeam")
            net.WriteUInt(TEAM_DEFEND, 8)
        net.SendToServer()
        surface.PlaySound("buttons/button14.wav")
        print("[SS CLIENT] Selected Defenders")
        return
    end
end)

-- Block other input during team select or round end
hook.Add("PlayerBindPress", "SS_BlockInputDuringTeamSelect", function(ply, bind, pressed)
    if SS.ShowTeamSelect or SS.ShowRoundEnd then
        return true -- Block all input
    end
end)
