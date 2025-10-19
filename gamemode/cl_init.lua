include("shared.lua")
include("cl_hud.lua")
include("cl_stealth.lua")

-- FORCE client-side team setup (in case it didn't sync from shared.lua)
TEAM_COLLECT = 1
TEAM_DEFEND = 2

team.SetUp(TEAM_COLLECT, "Collectors", Color(190,190,255), true)
team.SetUp(TEAM_DEFEND,  "Defenders",  Color(180,255,180), false)

-- Re-setup teams after a delay to override sandbox
timer.Simple(0.5, function()
    team.SetUp(TEAM_COLLECT, "Collectors", Color(190,190,255), true)
    team.SetUp(TEAM_DEFEND,  "Defenders",  Color(180,255,180), false)
    print("Client teams initialized:")
    print("Team 1:", team.GetName(1), team.GetColor(1))
    print("Team 2:", team.GetName(2), team.GetColor(2))
end)

-- Network receivers
net.Receive("SS_PageCount", function()
  local cur = net.ReadUInt(8)
  local goal = net.ReadUInt(8)
  SS.PageCount = cur
  SS.TargetPages = goal
end)

net.Receive("SS_RoundTimer", function()
  SS.ClientTimeLeft = net.ReadFloat()
end)

-- Debug command to check client teams
concommand.Add("ss_checkteams_client", function()
  print("\n=== CLIENT TEAM DEBUG ===")
  print("TEAM_COLLECT = " .. TEAM_COLLECT)
  print("  Name: " .. team.GetName(TEAM_COLLECT))
  print("  Color: " .. tostring(team.GetColor(TEAM_COLLECT)))
  
  print("\nTEAM_DEFEND = " .. TEAM_DEFEND)
  print("  Name: " .. team.GetName(TEAM_DEFEND))
  print("  Color: " .. tostring(team.GetColor(TEAM_DEFEND)))
  
  local me = LocalPlayer()
  if IsValid(me) then
    print("\nMy Team: " .. me:Team())
    print("My Team Name: " .. team.GetName(me:Team()))
    print("My Team Color: " .. tostring(team.GetColor(me:Team())))
  end
  print("==================\n")
end)

--==============================================
-- CLIENT-SIDE PAGE RENDERING
--==============================================
local ENT = {}
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:Draw()
    self:DrawModel()
    
    -- Add a large glow effect
    local pos = self:GetPos()
    
    -- Pulsing glow
    local pulse = math.abs(math.sin(CurTime() * 3)) * 0.5 + 0.5
    
    -- Big yellow sprite
    render.SetMaterial(Material("sprites/light_glow02_add"))
    render.DrawSprite(pos, 64 * pulse, 64 * pulse, Color(255, 255, 150, 255))
    
    -- Additional beam effect
    render.DrawSprite(pos, 128, 128, Color(255, 255, 200, 50))
    
    -- Draw "Press E to collect" hint when close
    local ply = LocalPlayer()
    if IsValid(ply) and ply:GetPos():Distance(pos) < 150 then
        if ply:Team() == 1 then -- TEAM_COLLECT
            local screenPos = pos:ToScreen()
            if screenPos.visible then
                draw.SimpleTextOutlined("Press E to collect", "Trebuchet24", screenPos.x, screenPos.y - 40, 
                    Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, 200))
                
                -- Distance indicator
                local dist = math.floor(ply:GetPos():Distance(pos))
                draw.SimpleText(dist .. " units", "Trebuchet18", screenPos.x, screenPos.y - 20, 
                    Color(200, 200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end
end

function ENT:DrawTranslucent()
    self:Draw()
end

scripted_ents.Register(ENT, "slender_page")
print("[SS CLIENT] Registered slender_page rendering!")

-- Fallback: Draw glowing sprites for all pages (in case model doesn't render)
hook.Add("PostDrawTranslucentRenderables", "SS_DrawPageSprites", function()
    local pages = ents.FindByClass("slender_page")
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    for _, page in ipairs(pages) do
        if IsValid(page) then
            local pos = page:GetPos()
            local pulse = math.abs(math.sin(CurTime() * 3)) * 0.5 + 0.5
            local dist = ply:GetPos():Distance(pos)
            
            -- Draw a big glowing orb
            render.SetMaterial(Material("sprites/light_glow02_add"))
            render.DrawSprite(pos, 128 * pulse, 128 * pulse, Color(255, 255, 150, 255))
            render.DrawSprite(pos, 200, 200, Color(255, 255, 100, 80))
            
            -- Draw beam to sky
            render.DrawBeam(pos, pos + Vector(0, 0, 500), 8, 0, 1, Color(255, 255, 150, 100))
            
            -- Draw hint text when close
            if dist < 150 and ply:Team() == TEAM_COLLECT then
                local screenPos = pos:ToScreen()
                if screenPos.visible then
                    draw.SimpleTextOutlined("Press E to collect", "DermaLarge", screenPos.x, screenPos.y - 50, 
                        Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, 200))
                    
                    draw.SimpleText(math.floor(dist) .. " units away", "DermaDefault", screenPos.x, screenPos.y - 25, 
                        Color(200, 200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
        end
    end
end)
