--==================================================
--  Slender Siege: Universal Ammo Spawner
--==================================================

local SPAWN_INTERVAL = 90       -- seconds between spawns
local MAX_SPAWNS = 8            -- max ammo boxes at once
local ENTITY_CLASS = "universal_ammo"

local spawnPositions = {}

-- Automatically collect valid spawn points across the map
hook.Add("InitPostEntity", "SS_FindAmmoSpawnPoints", function()
    spawnPositions = {}

    -- Use info_player_start and some map props as candidate positions
    for _, ent in ipairs(ents.FindByClass("info_player_start")) do
        table.insert(spawnPositions, ent:GetPos() + Vector(0, 0, 15))
    end

    for _, ent in ipairs(ents.FindByClass("info_player_deathmatch")) do
        table.insert(spawnPositions, ent:GetPos() + Vector(0, 0, 15))
    end

    print("[SS AmmoSpawner] Found " .. #spawnPositions .. " potential spawn points.")
end)

-- Helper: count existing ammo boxes
local function CountExistingAmmo()
    local count = 0
    for _, ent in ipairs(ents.FindByClass(ENTITY_CLASS)) do
        if IsValid(ent) then count = count + 1 end
    end
    return count
end

-- Periodically spawn ammo
timer.Create("SS_AmmoSpawner", SPAWN_INTERVAL, 0, function()
    if #spawnPositions == 0 then return end
    if CountExistingAmmo() >= MAX_SPAWNS then return end

    local spawnPos = table.Random(spawnPositions)
    local ammo = ents.Create(ENTITY_CLASS)
    if not IsValid(ammo) then return end

    ammo:SetPos(spawnPos + Vector(0, 0, 15))
    ammo:Spawn()

    print("[SS AmmoSpawner] Spawned universal ammo at " .. tostring(spawnPos))
end)

