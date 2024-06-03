--[[
  Maybe not the best approach to create this amount of scheduled events, but
  the visual effects is much nicer than the simpler solution in q5_2.lua

  If this is going to be used in other places too and/or too often, would be
  good to add this delay/decay inside the Combat class, like an adapted version
  of q5_2.lua

  Call: doTornadoEffectAtCreature(player)

  In game: say question five one
]]



-- Constants
local Q5_TORNADOS_PER_RADIUS = 20



-- Create tornado effect around the creature
local function doTornadoEffectAtCreature(creature, area)
  -- Get the origin
  local origin = creature:getPosition()

  -- Calculate the amount of ice tornados
  local tornados = area * Q5_TORNADOS_PER_RADIUS

  -- Create a maximum of tornados effects
  for _ = 1, tornados do
    -- Get random offset from origin
    local x = math.random(-area, area)
    local y = math.random(-area, area)

    -- Skip the creature location
    if x == 0 and y == 0 then
      goto continue
    end

    -- Limit the radius, skipping if outside the circle
    local dist = math.sqrt(x * x + y * y)

    if dist > area then
      goto continue
    end

    -- Random timer for nicer effects
    local t = math.random(0, 40) * 25

    -- Calculate effect position
    local pos = Position(origin)

    pos.x = pos.x + x
    pos.y = pos.y + y

    -- Check the tile
    local tile = Tile(pos)

    -- If can't get the tile, or it is not ground, or it is an inaccessible
    -- tile, skip it
    if tile == nil or tile:getGround() == false or tile:hasFlag(TILESTATE_IMMOVABLEBLOCKSOLID) == true then
      goto continue
    end

    -- Schedule the effect spawn event
    addEvent(
      function ()
        pos:sendMagicEffect(CONST_ME_ICETORNADO)
      end,
      t,
      pos
    )

    -- Skip
    ::continue::
  end
end



-- Handle the spell, creating ice tornados around the caster
function onCastSpell(creature, variant)
  -- Initialize spell's area as 3 and try to load the value from spells.xml
  local spell = Spell('Question Five One')
  local area = 3

  if spell ~= nil then
    area = spell:getRange()
  end

  -- Call the effect's handler
  doTornadoEffectAtCreature(creature, area)

  return true
end
