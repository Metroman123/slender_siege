-- Slender Siege Top Bar UI (Polished + Reliable Death X)
-- Darker team bands, dead slots greyed out with a thick red X.
-- Resets cleanly at the start of each round.

if CLIENT then
  SS = SS or {}
  SS.TopBar = SS.TopBar or {}
  local bar = SS.TopBar

  bar.Slots      = bar.Slots      or {}
  bar.Players    = bar.Players    or {}
  bar.DeathState = bar.DeathState or {}   -- true if slot is marked dead
  bar.PlyToSlot  = bar.PlyToSlot  or {}

  local SLOT_COUNT = 10
  local ICON_SIZE  = 32
  local SLOT_PAD   = 4

  local function CreateSlot()
    local avatar = vgui.Create("AvatarImage")
    avatar:SetSize(ICON_SIZE, ICON_SIZE)
    avatar:SetVisible(false)
    avatar:SetMouseInputEnabled(false)
    return avatar
  end

  local function resetAll()
    for i = 1, SLOT_COUNT do
      bar.Slots[i]      = bar.Slots[i] or CreateSlot()
      bar.Players[i]    = nil
      bar.DeathState[i] = false
    end
    bar.PlyToSlot = {}
  end

  function bar:Init()
    resetAll()
    self:Refresh()
  end

  function bar:Refresh()
    if not self.Slots or not self.Slots[1] then return end
    bar.PlyToSlot = {}

    local collectors, defenders = {}, {}
    for _, ply in ipairs(player.GetAll()) do
      if IsValid(ply) then
        if ply:Team() == TEAM_COLLECT then table.insert(collectors, ply)
        elseif ply:Team() == TEAM_DEFEND then table.insert(defenders, ply) end
      end
    end

    for i = 1, 5 do
      local ply = collectors[i]
      local avatar = bar.Slots[i]
      bar.Players[i] = ply

      if IsValid(ply) then
        avatar:SetPlayer(ply, ICON_SIZE)
        avatar:SetVisible(true)
        bar.PlyToSlot[ply] = i
        if not ply:Alive() then bar.DeathState[i] = true end
      else
        avatar:SetVisible(false)
        bar.DeathState[i] = false
      end
    end

    for i = 1, 5 do
      local idx = 5 + i
      local ply = defenders[i]
      local avatar = bar.Slots[idx]
      bar.Players[idx] = ply

      if IsValid(ply) then
        avatar:SetPlayer(ply, ICON_SIZE)
        avatar:SetVisible(true)
        bar.PlyToSlot[ply] = idx
        if not ply:Alive() then bar.DeathState[idx] = true end
      else
        avatar:SetVisible(false)
        bar.DeathState[idx] = false
      end
    end
  end

  local function DrawX(x, y, size)
    surface.SetDrawColor(255, 40, 40, 255)
    surface.DrawLine(x + 4, y + 4, x + size - 4, y + size - 4)
    surface.DrawLine(x + 4, y + size - 4, x + size - 4, y + 4)
    surface.DrawLine(x + 5, y + 4, x + size - 5, y + size - 4)
    surface.DrawLine(x + 4, y + 5, x + size - 4, y + size - 5)
  end

  hook.Add("HUDPaint", "SS_DrawTopBar", function()
    if not bar or not bar.Slots then return end
    local lp = LocalPlayer()
    if IsValid(lp) then
      local t = lp:Team()
      if t ~= TEAM_COLLECT and t ~= TEAM_DEFEND then return end
    end

    if SS and (SS.ShowTeamSelect or (SS.ROUND_STATE and SS.State == SS.ROUND_STATE.TEAM_SELECT)) then return end

    local screenW = ScrW()
    local totalW  = SLOT_COUNT * ICON_SIZE + (SLOT_COUNT - 1) * SLOT_PAD
    local startX  = (screenW - totalW) / 2
    local yPos    = 20
    local halfW   = totalW / 2

    surface.SetDrawColor(10, 20, 45, 210)
    surface.DrawRect(startX - 10, yPos - 8, halfW + 10, ICON_SIZE + 16)

    surface.SetDrawColor(45, 10, 10, 210)
    surface.DrawRect(startX + halfW, yPos - 8, halfW + 10, ICON_SIZE + 16)

    for i = 1, SLOT_COUNT do
      local avatar = bar.Slots[i]
      local slotX  = startX + (i - 1) * (ICON_SIZE + SLOT_PAD)

      avatar:SetPos(slotX, yPos)
      if avatar:IsVisible() then
        avatar:SetPaintedManually(true)
        avatar:PaintManual()
        avatar:SetPaintedManually(false)
      else
        surface.SetDrawColor(50, 50, 50, 200)
        surface.DrawRect(slotX, yPos, ICON_SIZE, ICON_SIZE)
      end

      local ply = bar.Players[i]
      if IsValid(ply) and not ply:Alive() then bar.DeathState[i] = true end
      if bar.DeathState[i] then
        surface.SetDrawColor(80, 80, 80, 230)
        surface.DrawRect(slotX, yPos, ICON_SIZE, ICON_SIZE)
        DrawX(slotX, yPos, ICON_SIZE)
      end
      surface.SetDrawColor(0, 0, 0, 255)
      surface.DrawOutlinedRect(slotX, yPos, ICON_SIZE, ICON_SIZE)
    end

    local gapCenter = startX + ICON_SIZE * 5 + SLOT_PAD * 4 + (SLOT_PAD / 2)
    surface.SetDrawColor(255, 255, 255, 200)
    surface.DrawRect(gapCenter - 1, yPos - 10, 2, ICON_SIZE + 20)

    draw.SimpleText("COLLECTORS", "Trebuchet18", startX + (totalW / 4),   yPos - 20, Color(130, 170, 255), TEXT_ALIGN_CENTER)
    draw.SimpleText("DEFENDERS",  "Trebuchet18", startX + (3*totalW / 4), yPos - 20, Color(255, 140, 140), TEXT_ALIGN_CENTER)
  end)

  timer.Create("SS_RefreshTopBar", 1, 0, function() if bar and bar.Refresh then bar:Refresh() end end)

  hook.Add("InitPostEntity", "SS_InitTopBarPanel", function() if bar and bar.Init then bar:Init() end end)

  local function markDead(ply)
    if not IsValid(ply) then return end
    local slot = bar.PlyToSlot[ply]
    if slot then bar.DeathState[slot] = true end
  end

  hook.Add("PlayerDeath", "SS_TopBar_PlayerDeath", function(victim) markDead(victim) end)
  hook.Add("PostPlayerDeath", "SS_TopBar_PostPlayerDeath", function(victim) markDead(victim) end)

  local function roundReset()
    if not bar then return end
    for i = 1, SLOT_COUNT do bar.DeathState[i] = false end
  end

  hook.Add("OnRoundStart",  "SS_TopBar_RoundReset1", roundReset)
  hook.Add("RoundStart",    "SS_TopBar_RoundReset2", roundReset)
  hook.Add("TTTBeginRound", "SS_TopBar_RoundReset3", roundReset)
  hook.Add("SS_RoundStart", "SS_TopBar_RoundReset4", roundReset)
end
