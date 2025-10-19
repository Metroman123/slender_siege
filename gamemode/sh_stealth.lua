SS = SS or {}

-- Tunables
CreateConVar("ss_hide_light", "0.08", FCVAR_ARCHIVE, "<= this ambient light = 'dark' (0..1)")
CreateConVar("ss_hide_maxspeed", "32", FCVAR_ARCHIVE, "Max speed to count as still")
CreateConVar("ss_hide_crouchbonus", "1", FCVAR_ARCHIVE, "Crouching relaxes speed requirement (0/1)")

function SS:IsDarkEnough(light)
  return light <= GetConVar("ss_hide_light"):GetFloat()
end
