-- ==========================================
-- SlenderBot Controller
-- Spawns safely with smart distance logic.
-- ==========================================

local SLENDER_CLASS = "npc_slenderman_twenty"
local ACTIVE_SLENDER = nil

-- Configurable behaviour
local SLENDER_SPAWN_INTERVAL = 60   -- seconds between possible spawns
local SLENDER_ACTIVE_TIME   = 25    -- seconds before it despawns
local SLENDER_SIGHT_RANGE   = 1200  -- how far Slender can "see"
local SLENDER_KILL_RANGE    = 180   -- distance to strike
local SLENDER_LERP_SPEED    = 0.04  -- movement lerp speed

-----------------------------------------------------------
-- CLEANUP
-----------------------------------------------------------
local function CleanupSlender()
    timer.Remove("SS_SlenderThink")
    timer.Remove("SS_SlenderCycle")
    if IsValid(ACTIVE_SLENDER) then
        ACTIVE_SLENDER:Remove()
    end
    ACTIVE_SLENDER = nil
end
hook.Add("PostCleanupMap", "SS_CleanupSlender", CleanupSlender)

-----------------------------------------------------------
-- SMART SPAWN POSITIONING
-----------------------------------------------------------
local function GetSmartSpawnPos()
    local allPlayers = {}
    for _, ply in ipairs(player.GetAll()) do
        -- Only consider collectors that are not hidden.  Hidden players
        -- (as flagged by SS_Hidden) should not attract the Slender spawn
        -- anchor.
        if IsValid(ply) and ply:Alive() and ply:Team() == TEAM_COLLECT
            and not ply:GetNWBool("SS_Hidden", false) then
            table.insert(allPlayers, ply)
        end
    end

    if #allPlayers == 0 then
        local spawns = ents.FindByClass("info_defender_spawn")
        if #spawns > 0 then
            return spawns[math.random(#spawns)]:GetPos() + Vector(0, 0, 16)
        else
            return Vector(0, 0, 0)
        end
    end

    local anchor = table.Random(allPlayers):GetPos()
    local attempts = 0
    local chosenPos = nil

    while attempts < 25 do
        attempts = attempts + 1

        local offset = VectorRand():GetNormalized() * math.Rand(700, 1500)
        offset.z = math.Rand(-32, 64)
        local testPos = anchor + offset

        local tooClose = false
        for _, ply in ipairs(allPlayers) do
            if ply:GetPos():DistToSqr(testPos) < (600 * 600) then
                tooClose = true
                break
            end
        end
        if tooClose then continue end

        local tr = util.TraceLine({
            start = testPos + Vector(0, 0, 256),
            endpos = testPos - Vector(0, 0, 512),
            mask = MASK_SOLID_BRUSHONLY
        })
        if not tr.Hit then continue end

        chosenPos = tr.HitPos + Vector(0, 0, 16)
        break
    end

    return chosenPos or anchor + Vector(0, 0, 64)
end

-----------------------------------------------------------
-- SPAWN SLENDER (Bon the Bunny)
-----------------------------------------------------------
local function SpawnSlender()
    if IsValid(ACTIVE_SLENDER) then return end

    local spawnPos = GetSmartSpawnPos()
    print("[SS] Attempting to spawn SlenderBot (" .. SLENDER_CLASS .. ") at: " .. tostring(spawnPos))

    local sl = ents.Create(SLENDER_CLASS)
    if not IsValid(sl) then
        print("[SS] ERROR: Failed to create entity class '" .. SLENDER_CLASS .. "'. Check DrGBase and addon installation.")
        return
    end

    sl:SetPos(spawnPos)
    sl:Spawn()

    if not IsValid(sl) then
        print("[SS] ERROR: Entity invalid immediately after spawn. Likely DrGBase blocked or auto-removed it.")
        return
    end

    sl:SetHealth(999999)
    sl:SetNWBool("SS_Unkillable", true)
    sl:SetCollisionGroup(COLLISION_GROUP_NPC)
    sl:SetKeyValue("ignoreplayers", "0")

    ACTIVE_SLENDER = sl
    PrintMessage(HUD_PRINTTALK, "[SS] The air grows cold... something is near.")
    print("[SS] Spawned entity successfully.")

    -------------------------------------------------------
    -- BEHAVIOUR LOOP
    -------------------------------------------------------
    timer.Create("SS_SlenderThink", 1, 0, function()
        if not IsValid(ACTIVE_SLENDER) then return end
        local slender = ACTIVE_SLENDER

        -- Gather visible targets
        local potentialTargets = {}
        for _, ply in ipairs(player.GetAll()) do
            -- Only target visible collectors who are not hidden.  If a player
            -- has SS_Hidden set, they are effectively invisible to the bot.
            if IsValid(ply) and ply:Alive() and ply:Team() == TEAM_COLLECT
                and not ply:GetNWBool("SS_Hidden", false) then
                local dist = ply:GetPos():DistToSqr(slender:GetPos())
                if dist < (SLENDER_SIGHT_RANGE * SLENDER_SIGHT_RANGE) then
                    -- Line of sight trace (can hide)
                    local tr = util.TraceLine({
                        start = slender:GetPos() + Vector(0,0,64),
                        endpos = ply:EyePos(),
                        filter = {slender}
                    })
                    if tr.Entity == ply then
                        table.insert(potentialTargets, ply)
                    end
                end
            end
        end

        if #potentialTargets == 0 then return end

        local target = table.Random(potentialTargets)
        local currentPos = slender:GetPos()
        local targetPos = target:GetPos()
        local newPos = LerpVector(SLENDER_LERP_SPEED, currentPos, targetPos)
        slender:SetPos(newPos)

        -- Build up "focus" before killing
        slender.FocusTarget = slender.FocusTarget or {}
        local focusData = slender.FocusTarget[target] or { timer = 0 }

        if not target:GetNWBool("SS_Hidden", false)
            and currentPos:DistToSqr(targetPos) < (SLENDER_KILL_RANGE * SLENDER_KILL_RANGE) then
            focusData.timer = focusData.timer + 1
            if focusData.timer >= 3 then
                target:KillSilent()
                PrintMessage(HUD_PRINTTALK, target:Nick() .. " was taken by Bon the Bunny...")
                focusData.timer = 0
            end
        else
            -- reduce focus if target is out of range or hidden
            focusData.timer = math.max(0, focusData.timer - 1)
        end

        slender.FocusTarget[target] = focusData
    end)

    -------------------------------------------------------
    -- DESPAWN AFTER ACTIVE TIME
    -------------------------------------------------------
    timer.Simple(SLENDER_ACTIVE_TIME, function()
        if IsValid(ACTIVE_SLENDER) then
            ACTIVE_SLENDER:Remove()
            ACTIVE_SLENDER = nil
            PrintMessage(HUD_PRINTTALK, "[SS] The eerie presence fades away...")
        end
    end)
end

-----------------------------------------------------------
-- SPAWN CYCLE LOOP
-----------------------------------------------------------
local function StartSlenderCycle()
    CleanupSlender()
    timer.Create("SS_SlenderCycle", SLENDER_SPAWN_INTERVAL, 0, function()
        if not IsValid(ACTIVE_SLENDER) then
            SpawnSlender()
        end
    end)
end

-----------------------------------------------------------
-- HOOKS
-----------------------------------------------------------
hook.Add("SS_BeginRound", "SS_SpawnSlenderBot", function()
    CleanupSlender()
    timer.Simple(5, StartSlenderCycle)
end)

hook.Add("SS_EndRound", "SS_StopSlender", CleanupSlender)

hook.Add("EntityTakeDamage", "SS_SlenderInvincible", function(ent, dmginfo)
    if IsValid(ent) and ent:GetNWBool("SS_Unkillable", false) then
        dmginfo:SetDamage(0)
        return true
    end
end)

