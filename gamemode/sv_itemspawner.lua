--==================================================
-- Slender Siege: Classic Horror Item Spawner
-- - Spawns ammo + rare wonder weapons on a classic cadence
-- - Shows 3D text labels above pickups (no halos)
-- - Navmesh-aware placement for better variety
--==================================================

if SERVER then
    -- Send this file to clients (for the 3D text drawing below)
    AddCSLuaFile()
end

--=====================
-- CONFIG
--=====================
local SPAWN_INTERVAL         = 45      -- seconds between spawn ticks (classic pacing)
local SPAWNS_PER_INTERVAL_MIN = 2      -- min items per tick
local SPAWNS_PER_INTERVAL_MAX = 3      -- max items per tick
local MAX_SPAWNS             = 5       -- keep this many active at once
local ENTITY_CLASS_AMMO      = "universal_ammo"

local WONDER_CHANCE          = 0.12    -- 12% chance a spawn is a wonder weapon
local WONDER_WEAPONS = {
    "tfa_shrinkray",
    "tfa_raygun",
    "tfa_wunderwaffe",
    "tfa_wavegun",
    "tfa_wintershowl",
    "tfa_blundergat"
}

--=====================
-- SERVER: Spawn logic
--=====================
if SERVER then
    local spawnPositions = {}
    local startPositions = {}

    local function gatherSpawnPositions()
        spawnPositions = {}
        startPositions = {}

        -- Use team spawns if you have them; also collect generic starts
        for _, ent in ipairs(ents.FindByClass("info_collector_spawn")) do
            table.insert(startPositions, ent:GetPos())
        end
        for _, ent in ipairs(ents.FindByClass("info_defender_spawn")) do
            table.insert(startPositions, ent:GetPos())
        end
        for _, ent in ipairs(ents.FindByClass("info_player_start")) do
            local pos = ent:GetPos()
            table.insert(startPositions, pos)
            table.insert(spawnPositions, pos + Vector(0,0,15))
        end
        for _, ent in ipairs(ents.FindByClass("info_player_deathmatch")) do
            local pos = ent:GetPos()
            table.insert(startPositions, pos)
            table.insert(spawnPositions, pos + Vector(0,0,15))
        end

        -- Add navmesh points for variety, but not too close to player starts
        if navmesh and navmesh.GetAllNavAreas then
            local areas = navmesh.GetAllNavAreas()
            if areas and #areas > 0 then
                -- shuffle
                for i = #areas, 2, -1 do
                    local j = math.random(i)
                    areas[i], areas[j] = areas[j], areas[i]
                end

                local added = 0
                local MAX_NAV_POS = 60
                for _, area in ipairs(areas) do
                    if added >= MAX_NAV_POS then break end
                    if IsValid(area) then
                        local p = area:GetRandomPoint()
                        if p then
                            local far = true
                            for _, sp in ipairs(startPositions) do
                                if p:DistToSqr(sp) < (600 * 600) then far = false break end
                            end
                            if far then
                                -- small random offset to avoid stacking
                                p = p + Vector(math.random(-24,24), math.random(-24,24), 16)
                                table.insert(spawnPositions, p)
                                added = added + 1
                            end
                        end
                    end
                end
                print(string.format("[SS Spawner] Navmesh points added: %d  (total: %d)",
                    added, #spawnPositions))
            else
                print("[SS Spawner] No navmesh areas found.")
            end
        else
            print("[SS Spawner] Navmesh not available. Using start points only.")
        end

        print("[SS Spawner] Candidate spawn positions: " .. tostring(#spawnPositions))
    end

    -- Register the spawn position gathering function to run after all entities
    -- have been created.  Placing this inside the SERVER block ensures that
    -- gatherSpawnPositions is in scope when the hook is added.
    hook.Add("InitPostEntity", "SS_ItemSpawner_FindSpawns", gatherSpawnPositions)

    local function CountExistingAmmo()
        local n = 0
        for _, e in ipairs(ents.FindByClass(ENTITY_CLASS_AMMO)) do
            if IsValid(e) then n = n + 1 end
        end
        -- count wonder weapons too
        for _, cls in ipairs(WONDER_WEAPONS) do
            for _, e in ipairs(ents.FindByClass(cls)) do
                if IsValid(e) then n = n + 1 end
            end
        end
        return n
    end

    -- Helper: spawn one pickup at a random candidate position
    local function SpawnOnePickup()
    if #spawnPositions == 0 then return end
    local pos = spawnPositions[math.random(#spawnPositions)]

    -- small jitter to avoid exact repeats
    pos = pos + Vector(math.random(-16,16), math.random(-16,16), 0)

    local function SpawnMarker(parentEnt, isAmmo, label)
        if not IsValid(parentEnt) then return end

        -- Visible glowing orb (env_sprite) as a marker
        local marker = ents.Create("env_sprite")
        if not IsValid(marker) then return end

        marker:SetPos(parentEnt:GetPos() + Vector(0,0,30))
        marker:SetKeyValue("model", "sprites/light_glow02_add.vmt")
        marker:SetKeyValue("rendermode", "5") -- additive
        marker:SetKeyValue("framerate", "10")
        marker:SetKeyValue("spawnflags", "1") -- start on
        marker:SetKeyValue("scale", "0.20")

        -- color: ammo = warm yellow, wonder = red
        if isAmmo then
            marker:SetKeyValue("rendercolor", "255 215 0")
            marker:SetKeyValue("GlowProxySize", "16")
        else
            marker:SetKeyValue("rendercolor", "220 60 60")
            marker:SetKeyValue("GlowProxySize", "16")
        end

        marker:Spawn()
        marker:Activate()

        -- parent to pickup so it follows and auto-cleans on remove
        marker:SetParent(parentEnt)

        -- tag so client draws text above marker
        marker:SetNWBool("SS_PickupMarker", true)
        marker:SetNWString("SS_Label", label or (isAmmo and "AMMO" or ""))
    end

    local doWonder = (math.random() < WONDER_CHANCE)
    if doWonder then
        local cls = WONDER_WEAPONS[math.random(#WONDER_WEAPONS)]
        local wep = ents.Create(cls)
        if not IsValid(wep) then
            print("[SS Spawner] Failed to create wonder weapon " .. tostring(cls))
            return
        end
        wep:SetPos(pos)
        wep:Spawn()
        wep:SetNWBool("SS_Pickup", true)
        wep:SetNWString("SS_Label", cls)

        -- spawn visible marker above it
        SpawnMarker(wep, false, cls)
        return
    else
        local ammo = ents.Create(ENTITY_CLASS_AMMO)
        if not IsValid(ammo) then
            print("[SS Spawner] Failed to create ammo entity")
            return
        end
        ammo:SetPos(pos)
        ammo:Spawn()
        ammo:SetNWBool("SS_Pickup", true)
        ammo:SetNWString("SS_Label", "AMMO")

        -- spawn visible marker above it
        SpawnMarker(ammo, true, "AMMO")
        return
    end
    end

    -- Periodically spawn new pickups on the server until the maximum
    -- number of active items is reached.  This timer runs every
    -- SPAWN_INTERVAL seconds and spawns a random number of items
    -- between SPAWNS_PER_INTERVAL_MIN and SPAWNS_PER_INTERVAL_MAX.
    timer.Create("SS_ItemSpawner", SPAWN_INTERVAL, 0, function()
        if #spawnPositions == 0 then return end
        local active = CountExistingAmmo()
        if active >= MAX_SPAWNS then return end
        local toSpawn = math.random(SPAWNS_PER_INTERVAL_MIN, SPAWNS_PER_INTERVAL_MAX)
        for i = 1, toSpawn do
            if CountExistingAmmo() >= MAX_SPAWNS then break end
            SpawnOnePickup()
        end
    end)

end -- close SERVER block

--=====================
-- CLIENT: 3D labels
--=====================
if CLIENT then
    local LABEL_FONT = "Trebuchet24"
    local FADE_MAX   = 1000
    local Z_OFFSET   = 24 -- add a bit above the sprite so no overlap

    local function drawLabelAtPos(worldPos, text, col)
        local lp = LocalPlayer()
        if not IsValid(lp) then return end

        local pos = worldPos + Vector(0,0,Z_OFFSET)
        local dist = lp:EyePos():Distance(pos)
        if dist >= FADE_MAX then return end
        local alpha = 255 * math.max(0, 1 - (dist / FADE_MAX))
        local ang = Angle(0, lp:EyeAngles().y - 90, 90)

        cam.Start3D2D(pos, ang, 0.2)
            draw.SimpleTextOutlined(
                text,
                LABEL_FONT,
                0, 0,
                Color(col.r, col.g, col.b, alpha),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                2, Color(0, 0, 0, alpha)
            )
        cam.End3D2D()
    end

    hook.Add("PostDrawTranslucentRenderables", "SS_DrawPickupLabels_Markers", function()
        -- Only draw above our explicit markers (env_sprite with NW flag)
        for _, m in ipairs(ents.FindByClass("env_sprite")) do
            if IsValid(m) and m:GetNWBool("SS_PickupMarker", false) then
                local label = m:GetNWString("SS_Label", "")
                if label ~= "" then
                    local isAmmo = (label == "AMMO")
                    local col = isAmmo and Color(255, 215, 0) or Color(220, 60, 60)
                    drawLabelAtPos(m:GetPos(), label, col)
                end
            end
        end
    end)
end


