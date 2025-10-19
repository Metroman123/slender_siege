SS = SS or {}
SS.PageCount = SS.PageCount or 0
SS.TargetPages = SS.TargetPages or (GetConVar("ss_target_pages") and GetConVar("ss_target_pages"):GetInt()) or 20
SS.ClientTimeLeft = 0

hook.Add("HUDPaint", "SS_HUD", function()
  local w,h = ScrW(), ScrH()
  draw.RoundedBox(8, 20, 20, 260, 64, Color(0,0,0,180))
  draw.SimpleText("Pages", "Trebuchet24", 36, 32, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
  draw.SimpleText((SS.PageCount or 0) .. " / " .. (SS.TargetPages or 20), "Trebuchet24", 36, 56, Color(170,220,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

  local t = math.max(0, SS.ClientTimeLeft or 0)
  local m = math.floor(t/60)
  local s = math.floor(t%60)
  local stamp = string.format("%02d:%02d", m, s)
  surface.SetFont("Trebuchet24")
  local tw,th = surface.GetTextSize(stamp)
  draw.RoundedBox(8, w - tw - 40, 20, tw + 20, 40, Color(0,0,0,180))
  draw.SimpleText(stamp, "Trebuchet24", w - tw - 30, 32, Color(255,220,170), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end)

hook.Add("HUDShouldDraw", "SS_HideCrosshair", function(n)
  if n == "CHudCrosshair" then return false end
end)

-------------------------------------------------
-- TEAM DISPLAY (bottom center of screen)
-------------------------------------------------
hook.Add("HUDPaint", "SS_TeamDisplay", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    -- Get team data safely
    local teamid   = ply:Team()
    local teamname = team.GetName(teamid) or "Unassigned"
    
    -- Force correct colors (override any sandbox defaults)
    local teamcol = Color(255, 255, 255)
    if teamid == 1 then
        teamcol = Color(190, 190, 255) -- Collectors
    elseif teamid == 2 then
        teamcol = Color(180, 255, 180) -- Defenders
    else
        teamcol = team.GetColor(teamid) or Color(255, 255, 255)
    end

    -- Box size / position
    local boxW, boxH = 240, 40
    local boxX = (ScrW() - boxW) / 2
    local boxY = ScrH() - 60

    -- Draw background box
    surface.SetDrawColor(0, 0, 0, 180)
    surface.DrawRect(boxX, boxY, boxW, boxH)

    -- Border (optional, subtle)
    surface.SetDrawColor(teamcol.r, teamcol.g, teamcol.b, 200)
    surface.DrawOutlinedRect(boxX, boxY, boxW, boxH, 2)

    -- Draw text
    draw.SimpleTextOutlined(
        "TEAM: " .. string.upper(teamname),
        "Trebuchet24",
        ScrW() / 2,
        boxY + (boxH / 2),
        teamcol,
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_CENTER,
        1,
        Color(0, 0, 0, 160)
    )
end)
