SS = SS or {}
SS.ClientHidden = false
SS._hideLerp = 0

--[[
  Track the last time the local player fired a weapon. When a shot is
  fired we briefly suppress stealth so that players cannot remain
  hidden while shooting. The variable `lastShot` stores the timestamp
  of the most recent shot and is consulted when determining whether
  the player should be hidden. A value of 0 indicates no shots have
  been fired recently.
--]]
local lastShot = 0

local lightCacheT, lightCacheVal = 0, 1

local function GetAmbientLight()
  if CurTime() >= lightCacheT then
    local v = render.GetLightColor(EyePos())
    local m = math.Clamp((v.x + v.y + v.z) / 3, 0, 1)
    lightCacheVal = m
    lightCacheT = CurTime() + 0.1
  end
  return lightCacheVal
end

local function IsPlayerStillOrCrouched(ply)
  -- Updated stealth requirement: players must be crouching to be
  -- considered for stealth. We intentionally drop the speed check
  -- from the original implementation to simplify the hiding logic.
  return ply:Crouching()
end

hook.Add("Think", "SS_UpdateHiddenState", function()
  local ply = LocalPlayer()
  if not IsValid(ply) or not ply:Alive() then
    SS.ClientHidden = false
    SS._hideLerp = 0
    return
  end
  -- Determine whether the player should be hidden based on crouching,
  -- ambient light level and recent shooting activity.  Players only
  -- hide if they are crouching in sufficiently dark conditions and
  -- have not fired a weapon within the last second.  The `lastShot`
  -- variable is updated elsewhere via the EntityFireBullets hook.
  local darkEnough = SS:IsDarkEnough(GetAmbientLight())
  local crouching  = IsPlayerStillOrCrouched(ply)
  local sinceShot  = CurTime() - (lastShot or 0)
  local canHide    = darkEnough and crouching and sinceShot > 1.0
  local target = canHide and 1 or 0
  SS._hideLerp = Lerp(FrameTime() * 4, SS._hideLerp, target)
  SS.ClientHidden = (SS._hideLerp > 0.02)
end)

-- Send hidden ping to server so teammates can see us
local nextPing = 0
hook.Add("Think", "SS_SendHiddenPing", function()
  if CurTime() < nextPing then return end
  nextPing = CurTime() + 1.0
  net.Start("SS_HiddenPing")
    net.WriteBool(SS.ClientHidden)
  net.SendToServer()
end)

--[[
  Whenever the local player fires a weapon this hook records the time of
  the shot and immediately forces the player out of stealth.  The
  subsequent Think cycle will decide when the player can return to
  stealth based on crouching and ambient lighting.
--]]
hook.Add("EntityFireBullets", "SS_UnhideOnShoot", function(ent, data)
  if ent ~= LocalPlayer() then return end
  lastShot = CurTime()
  -- If we were hidden at the moment of firing, cancel hide state and
  -- notify the server immediately.  We reset _hideLerp to zero so
  -- the transition back into stealth is smooth.
  if SS.ClientHidden then
    SS.ClientHidden = false
    SS._hideLerp = 0
    net.Start("SS_HiddenPing")
      net.WriteBool(false)
    net.SendToServer()
  end
end)

-- Visual effect
hook.Add("RenderScreenspaceEffects", "SS_HiddenBWEffect", function()
  if not SS.ClientHidden then return end
  local f = SS._hideLerp or 0
  local tab = {
    ["$pp_colour_addr"]       = 0,
    ["$pp_colour_addg"]       = 0,
    ["$pp_colour_addb"]       = 0,
    ["$pp_colour_brightness"] = -0.03 * f,
    ["$pp_colour_contrast"]   = 1 + (0.15 * f),
    ["$pp_colour_colour"]     = 1 - (0.95 * f),
    ["$pp_colour_mulr"]       = 0,
    ["$pp_colour_mulg"]       = 0,
    ["$pp_colour_mulb"]       = 0
  }
  DrawColorModify(tab)
end)

-- Team visibility: highlight hidden teammates so they can still see each other
hook.Add("PreDrawHalos", "SS_HiddenTeammateHalo", function()
  local me = LocalPlayer()
  if not IsValid(me) then return end
  local myTeam = me:Team()
  local allies = {}
  for _, ply in ipairs(player.GetAll()) do
    if ply ~= me and ply:Team() == myTeam and ply:GetNWBool("SS_Hidden", false) then
      table.insert(allies, ply)
    end
  end
  if #allies > 0 then
    -- soft green halo; alpha is controlled by engine
    halo.Add(allies, Color(120, 255, 140), 2, 2, 1, true, true)
  end
end)


