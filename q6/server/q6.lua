-- Constants
local EXTENDED_OPCODE_CUSTOM_SPELL_EFFECT = 137



-- Spell's effect
local function teleportPlayerBy(player, range, cooldown)
  -- Get player's direction
  local direction = player:getDirection()

  -- Initialize the path data
  local targetPosition = nil
  local effectiveAmount = 0

  for i = 1, range do
    -- Initialize with the player's position
    local pos = player:getPosition()

    -- Calculate the target position based on player's direction
    if direction == DIRECTION_NORTH then
      pos.y = pos.y - i
    elseif direction == DIRECTION_EAST then
      pos.x = pos.x + i
    elseif direction == DIRECTION_SOUTH then
      pos.y = pos.y + i
    elseif direction == DIRECTION_WEST then
      pos.x = pos.x - i
    end

    -- Get tile at the calculated position
    local tile = Tile(pos)

    -- If can't get the tile, or it is not ground, or it is an inaccessible
    -- tile, break the path finding
    if tile == nil or tile:getGround() == false or tile:hasFlag(TILESTATE_IMMOVABLEBLOCKSOLID) == true then
      break
    end

    -- Store the current available path data
    targetPosition = pos
    effectiveAmount = i
  end

  -- If there is a position to teleport player to, do it
  if targetPosition ~= nil then
    player:teleportTo(targetPosition, false)
  end

  -- Send the spell data to player
  local buffer = string.format(
    'q6;%d;%d;%d',
    direction,
    effectiveAmount,
    cooldown
  )

  player:sendExtendedOpcode(EXTENDED_OPCODE_CUSTOM_SPELL_EFFECT, buffer)
end



-- Handle the spell, teleporting the caster by the spell's effect distance (at
-- most, stopping if path is blocked)
function onCastSpell(creature, variant)
  -- Get spell's range and cooldown
  local spell = Spell('Question Six')
  local range = 5
  local cooldown = 1000

  if spell ~= nil then
    range = spell:getRange()
    cooldown = spell:getCooldown()
  end

  -- Teleport the player
  teleportPlayerBy(creature, range, cooldown)

  return true
end
