-- Slender Siege Top Bar UI
-- This file draws a top‑screen team tracker similar to the team line‑ups in Rainbow Six Siege.
-- It shows up to five Collectors on the left and five Defenders on the right. Each slot displays
-- the player's Steam avatar and draws a red X over the slot when the player is dead.

if CLIENT then
  -- Ensure the Slender Siege namespace exists and a TopBar table is present.  
  -- We avoid creating a global variable named `TopBar`; instead we keep the
  -- reference on the `SS` table and use a local alias `bar` for readability.
  SS = SS or {}
  SS.TopBar = SS.TopBar or {}
  local bar = SS.TopBar

  -- Make sure internal tables exist. These hold avatar panels and associated players.
  bar.Slots   = bar.Slots   or {}
  bar.Players = bar.Players or {}

  -- Configuration constants defining slot count, size and padding.
  local SLOT_COUNT = 10       -- Total number of slots (5 per team)
  local ICON_SIZE  = 32       -- Size of each avatar icon
  local SLOT_PAD   = 4        -- Padding between slots

  -- Create an AvatarImage panel for a slot.  
  -- These panels display the player's Steam avatar and are hidden until populated.
  local function CreateSlot()
    local avatar = vgui.Create("AvatarImage")
    avatar:SetSize(ICON_SIZE, ICON_SIZE)
    avatar:SetVisible(false)           -- Hide by default until assigned to a player
    avatar:SetMouseInputEnabled(false) -- Disable mouse input so they don't interfere with clicks
    return avatar
  end

  -- Initialise the top bar by creating the avatar panels for each slot and then refreshing.
  function bar:Init()
    for i = 1, SLOT_COUNT do
      self.Slots[i] = CreateSlot()
      self.Players[i] = nil
    end
    self:Refresh()
  end

  -- Refresh the assignment of players to slots.  
  -- This should be called whenever the team composition changes (players join, leave, die, or switch teams).
  -- Collectors fill the first five slots and Defenders fill the last five.
  function bar:Refresh()
    -- Guard against running Refresh before slots have been created.  
    -- `Init` populates `bar.Slots`; if it hasn't run yet, skip this refresh call.
    if not self.Slots or not self.Slots[1] then return end

    local collectors = {}
    local defenders  = {}
    -- Gather players by team
    for _, ply in ipairs(player.GetAll()) do
      if ply:Team() == TEAM_COLLECT then
        collectors[#collectors + 1] = ply
      elseif ply:Team() == TEAM_DEFEND then
        defenders[#defenders + 1] = ply
      end
    end
    -- Assign Collectors to slots 1–5
    for i = 1, 5 do
      local ply = collectors[i]
      self.Players[i] = ply
      local avatar = self.Slots[i]
      if IsValid(ply) then
        avatar:SetPlayer(ply, ICON_SIZE)
        avatar:SetVisible(true)
      else
        avatar:SetVisible(false)
      end
    end
    -- Assign Defenders to slots 6–10
    for i = 1, 5 do
      local ply = defenders[i]
      self.Players[5 + i] = ply
      local avatar = self.Slots[5 + i]
      if IsValid(ply) then
        avatar:SetPlayer(ply, ICON_SIZE)
        avatar:SetVisible(true)
      else
        avatar:SetVisible(false)
      end
    end
  end

  -- Draw a red X across a slot to indicate a dead player.
  local function DrawX(x, y, size)
    surface.SetDrawColor(255, 0, 0, 220)
    surface.DrawLine(x + 4, y + 4, x + size - 4, y + size - 4)
    surface.DrawLine(x + 4, y + size - 4, x + size - 4, y + 4)
  end

  -- HUDPaint hook draws the top bar. It positions each avatar panel and draws overlays.
  hook.Add("HUDPaint", "SS_DrawTopBar", function()
    -- Validate the bar and its slots before drawing
    if not bar or not bar.Slots then return end

    -- Only draw the top bar for players who have already joined a team.
    -- If the local player is unassigned or a spectator, we skip drawing to
    -- avoid interfering with the team selection UI.  The team constants are
    -- defined in shared.lua.  This ensures the bar does not appear until
    -- after the player has selected Collectors or Defenders.
    local lp = LocalPlayer()
    if IsValid(lp) then
      local t = lp:Team()
      -- Only show the bar for players on the two main teams.  If the team
      -- constants haven't been defined yet, skip this check to avoid errors.
      if TEAM_COLLECT and TEAM_DEFEND then
        if t ~= TEAM_COLLECT and t ~= TEAM_DEFEND then
          return
        end
      end
    end

    -- Don't draw the top bar during the team selection screen.  
    -- Check both the high‑level round state and the local flag used by the
    -- team selection menu.  When SS.ShowTeamSelect is true the team
    -- selection UI is active on the client, and SS.State is set to
    -- TEAM_SELECT at the start of a new round.  Hiding the bar in both
    -- cases prevents it from interfering with the team selection flow.
    if SS then
      -- If the client has been told to show the team select menu via network,
      -- hide the top bar.  This flag is set by cl_teamselect.lua and should be
      -- respected even if SS.State is not yet updated.
      if SS.ShowTeamSelect == true then
        return
      end
      -- Safely check the round state if the ROUND_STATE table is available.
      -- In some cases SS.ROUND_STATE may not be defined yet (e.g. during
      -- early loading), so guard against indexing nil.  Only hide the
      -- top bar if both exist and the current state is TEAM_SELECT.
      if SS.ROUND_STATE and SS.State == SS.ROUND_STATE.TEAM_SELECT then
        return
      end
    end
    local screenW = ScrW()
    -- Total width of the bar (icons + padding between them)
    local totalW = SLOT_COUNT * ICON_SIZE + (SLOT_COUNT - 1) * SLOT_PAD
    local startX = (screenW - totalW) / 2
    local yPos = 10
    for i = 1, SLOT_COUNT do
      local avatar = bar.Slots[i]
      local slotX = startX + (i - 1) * (ICON_SIZE + SLOT_PAD)
      avatar:SetPos(slotX, yPos)
      if avatar:IsVisible() then
        -- Draw the avatar manually so we can control its position.
        avatar:SetPaintedManually(true)
        avatar:PaintManual()
        avatar:SetPaintedManually(false)
      else
        -- Draw a placeholder box if no player occupies this slot.
        surface.SetDrawColor(50, 50, 50, 180)
        surface.DrawRect(slotX, yPos, ICON_SIZE, ICON_SIZE)
      end
      -- Overlay an X if the assigned player is dead.
      local ply = bar.Players[i]
      if IsValid(ply) and not ply:Alive() then
        DrawX(slotX, yPos, ICON_SIZE)
      end
    end
    
    -- Draw a white divider bar between Collectors (left 5 slots) and Defenders (right 5 slots).
    -- Instead of using the slot padding width, compute the centre of the gap
    -- between the fifth and sixth slots and draw a thicker vertical bar
    -- centred on that point.  Increasing the width makes the separation
    -- significantly more visible on screen.  The bar spans the full height
    -- of the avatar icons.
    do
      -- Centre of the gap between slot 5 and slot 6.  There are five icons
      -- and four padding gaps before the divider, then half of the final
      -- padding.  This positions the bar exactly in the middle.
      local gapCenter = startX + ICON_SIZE * 5 + SLOT_PAD * 4 + (SLOT_PAD / 2)
      -- Choose a divider width wider than the slot padding for visibility.
      local dividerWidth = SLOT_PAD * 2
      surface.SetDrawColor(255, 255, 255, 255)
      surface.DrawRect(gapCenter - dividerWidth / 2, yPos + 1, dividerWidth, ICON_SIZE - 2)
    end
  end)

  -- Timer to refresh the bar every second. Adjust this interval if you want more/less frequent updates.
  timer.Create("SS_RefreshTopBar", 1, 0, function()
    if bar and bar.Refresh then
      bar:Refresh()
    end
  end)

  -- Initialise the top bar when all entities are loaded. This ensures vgui functions are ready.
  hook.Add("InitPostEntity", "SS_InitTopBarPanel", function()
    if bar and bar.Init then
      bar:Init()
    end
  end)
end