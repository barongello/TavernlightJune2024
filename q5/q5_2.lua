--[[
  Simpler effect, but not visually nice as q5_1.lua

  If this is going to be used in other places too and/or too often, would be
  good to add this delay/decay inside the Combat class, like an adapted version
  of this code

  In game: say question five two
]]



-- Initialize the combat's object
local combat = Combat()

combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_ICEDAMAGE)
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_ICETORNADO)
combat:setArea(createCombatArea(AREA_CIRCLE3X3))



-- Handle the spell, creating ice tornados around the caster
function onCastSpell(creature, variant)
  return combat:execute(creature, variant)
end
