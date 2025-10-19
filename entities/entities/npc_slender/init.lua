AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.PrintName = "Slender"
ENT.Spawnable = false

local SEEK_RADIUS = 3000
local TICK = 0.4

function ENT:Initialize()
  if SERVER then
    self:SetModel("models/Combine_Soldier.mdl") -- placeholder; replace with your workshop model
    self.Loco:SetDesiredSpeed(160)
    self:SetHealth(99999)
  end
end

function ENT:RunBehaviour()
  while (true) do
    local target = self:FindTarget()
    if IsValid(target) then
      self:StartActivity(ACT_RUN)
      self:ChaseTarget(target)
      self:StartActivity(ACT_IDLE)
    else
      self:StartActivity(ACT_WALK)
      self:MoveToPos(self:GetPos() + VectorRand()*math.random(200,600))
      self:StartActivity(ACT_IDLE)
      coroutine.wait(TICK)
    end
  end
end

function ENT:FindTarget()
  local best, bd = nil, math.huge
  for _,ply in ipairs(player.GetAll()) do
    if ply:Alive() and ply:Team() == TEAM_COLLECT then
      local d = self:GetPos():DistToSqr(ply:GetPos())
      -- If the player has "hidden" flag, reduce their priority unless very close
      if ply:GetNWBool("SS_Hidden", false) and d > (200*200) then
        d = d * 4 -- deprioritize hidden players at distance
      end
      if d < (SEEK_RADIUS*SEEK_RADIUS) and d < bd then best, bd = ply, d end
    end
  end
  return best
end

function ENT:ChaseTarget(ply)
  if not IsValid(ply) then return end
  self:MoveToPos(ply:GetPos(), {lookahead = 120, tolerance = 20})
  if IsValid(ply) and self:GetRangeTo(ply) < 75 then
    ply:ViewPunch(Angle(math.random(-4,4), math.random(-4,4), 0))
    ply:EmitSound("npc/stalker/go_alert2a.wav", 70)
  end
end
