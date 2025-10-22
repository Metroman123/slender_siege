AddCSLuaFile()

ENT.Type = "point"
ENT.Base = "base_point"
ENT.PrintName = "Collector Spawn Point"
ENT.Author = "Nicholas Morin"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Slender Siege"

function ENT:Initialize()
    -- Nothing needed for spawn points
end

function ENT:KeyValue(key, value)
    -- For Hammer editor support
end
