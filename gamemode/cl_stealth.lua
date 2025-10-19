SS = SS or {}
SS.ClientHidden = false
SS._hideLerp = 0

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
  local maxSpd = GetConVar("ss_hide_maxspeed"):GetFloat()
  local vel2d = ply:GetVelocity():Length2D()
  if vel2d <= maxSpd then return true end
  if GetConVar("ss_hide_crouchbonus"):GetBool() and ply:Crouching() and vel2d <= (maxSpd * 1.6) then
    return true
  end
  return false
end

hook.Add("Think", "SS_UpdateHiddenState", function()
  local ply = LocalPlayer()
  if not IsValid(ply) or not ply:Alive() then
    SS.ClientHidden = false
    SS._hideLerp = 0
    return
  end
  local wantHidden = SS:IsDarkEnough(GetAmbientLight()) and IsPlayerStillOrCrouched(ply)
  local target = wantHidden and 1 or 0
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

-- Optional HUD cue
hook.Add("HUDPaint", "SS_HiddenHint", function()
  local f = SS._hideLerp or 0
  if f <= 0.05 then return end
  local a = 180 * f
  surface.SetDrawColor(0, 0, 0, a)
  surface.DrawRect(20, ScrH() - 36, 72, 16)
  draw.SimpleText("HIDDEN", "Trebuchet18", 56, ScrH() - 28, Color(200, 255, 200, a + 30), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)
