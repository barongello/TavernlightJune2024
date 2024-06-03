-- Constants
local EXTENDED_OPCODE_CUSTOM_SPELL_EFFECT = 137



-- Custom spell effect constants
local CSE_Q6_MAP_BORDER_SIZE = 1
local CSE_Q6_CLONE_TILE_SPACING = 0.6



-- Handlers
local cseQ6OverlayWindow = nil
local cseQ6ResetOutfitEvent = nil



-- Utility function to split a string by a separator
local function split(input, separator)
  if separator == nil then
    separator = '%s'
  end

  local tokens = {}

  for token in string.gmatch(input, '([^' .. separator .. ']+)') do
    table.insert(tokens, token)
  end

  return tokens
end



-- Utility function to get all the needed map overlay data
local function getMapOverlayData()
  -- Get the map panel
  local gameMapPanel = modules.game_interface.getMapPanel()

  -- Get map properties
  local mapWidth = gameMapPanel:getWidth()
  local mapHeight = gameMapPanel:getHeight()
  local mapDimensions = gameMapPanel:getVisibleDimension()
  local mapAspectRatio = mapDimensions.width / mapDimensions.height

  -- Initialize the overlay size
  local overlaySize = {
    width = 0,
    height = 0
  }

  -- Initialize the overlay margins
  local overlayMargins = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0
  }

  -- Calculate the full size of borders
  local borderSize = CSE_Q6_MAP_BORDER_SIZE * 2

  -- Set the overlay's size and margins according to viewport
  if mapWidth > mapHeight then
    overlaySize.height = mapHeight - borderSize
    overlaySize.width = mapHeight * mapAspectRatio - borderSize

    local horizontalMargin = (mapWidth - overlaySize.width) * 0.5

    overlayMargins.left = horizontalMargin
    overlayMargins.right = horizontalMargin
  else
    overlaySize.width = mapWidth - borderSize
    overlaySize.height = mapWidth / mapAspectRatio - borderSize

    local verticalMargin = (mapHeight - overlaySize.height) * 0.5

    overlayMargins.top = verticalMargin
    overlayMargins.bottom = verticalMargin
  end

  -- Get the center tile
  local originTile = {
    x = math.floor(mapDimensions.width / 2),
    y = math.floor(mapDimensions.height / 2)
  }

  -- Get the tile size
  local tileSize = {
    width = overlaySize.width / mapDimensions.width,
    height = overlaySize.height / mapDimensions.height
  }

  return {
    margins = overlayMargins,
    originTile = originTile,
    tileSize = tileSize
  }
end



-- Destroy all creatures from question six's overlay window
local function q6DestroyOverlayChildren()
  if cseQ6OverlayWindow == nil then
    return
  end

  local children = cseQ6OverlayWindow:getChildren()

  for i = 1, #children do
    local creature = children[i]

    creature:destroy()
  end
end



-- Handle the effect of the question 6 spell
local function q6SpellEffect(direction, amountTeleported, duration)
  -- Get the local player
  local player = g_game.getLocalPlayer()

  -- Add the red outline to it
  player:setOutfitShader("outfit_outline")

  -- Block its walk for the effect duration, so it does not mess with the effect
  player:lockWalk(duration)

  -- If there is a scheduled event, reset it
  if cseQ6ResetOutfitEvent ~= nil then
    removeEvent(cseQ6ResetOutfitEvent)

    cseQ6ResetOutfitEvent = nil
  end

  -- Schedule an event to reset the player's shader and the overlay (using an
  -- anonymous function to take advantage of the closure)
  cseQ6ResetOutfitEvent = scheduleEvent(
    function ()
      player:setOutfitShader("outfit_default")

      if cseQ6OverlayWindow ~= nil then
        q6DestroyOverlayChildren()

        cseQ6OverlayWindow:hide()
      end

      cseQ6ResetOutfitEvent = nil
    end,
    duration
  )

  -- If the overlay was not created, nothing more to do
  if cseQ6OverlayWindow == nil then
    return
  end

  -- Get the overlay data
  local mapOverlayData = getMapOverlayData()

  -- Position the overlay correctly
  cseQ6OverlayWindow:setMarginLeft(mapOverlayData.margins.left)
  cseQ6OverlayWindow:setMarginRight(mapOverlayData.margins.right)
  cseQ6OverlayWindow:setMarginTop(mapOverlayData.margins.top)
  cseQ6OverlayWindow:setMarginBottom(mapOverlayData.margins.bottom)

  -- Get the overlay actual position
  local overlayPosition = cseQ6OverlayWindow:getPosition()

  -- Calculate the origin's top left position
  -- Need to subtract 1 from the origin tile because the visible dimension
  -- includes 2 extra tiles in each direction
  local origin = {
    x = overlayPosition.x + (mapOverlayData.originTile.x - 1) * mapOverlayData.tileSize.width,
    y = overlayPosition.y + (mapOverlayData.originTile.y - 1) * mapOverlayData.tileSize.height
  }

  -- Get the player outfit
  local playerOutfit = player:getOutfit()

  -- Calculate the clones amount (+1 to render over the player in the player's
  -- position)
  local clones = amountTeleported + 1

  -- Initialize clones' properties
  -- Do not use clones when calculating the opacity step, because it would make
  -- the last clone full opaque, if not rendering the clone over the player (
  -- a.k.a. not adding +1 to amountTeleported in the clones variable)
  local cloneWidth = mapOverlayData.tileSize.width * 2
  local cloneHeight = mapOverlayData.tileSize.height * 2
  local cloneOpacityStep = 1.0 / (amountTeleported + 1)

  -- Iterate over clones to create, position, resize, change look, direction and
  -- fade them accordingly
  for i = 1, clones do
    local creature = g_ui.createWidget('UICreature', cseQ6OverlayWindow)

    if creature == nil then
      goto continue
    end

    local pos = {
      x = origin.x,
      y = origin.y
    }

    local multiplier = (amountTeleported - i + 1) * CSE_Q6_CLONE_TILE_SPACING

    if direction == Directions.North then
      pos.y = pos.y + mapOverlayData.tileSize.height * multiplier
    elseif direction == Directions.East then
      pos.x = pos.x - mapOverlayData.tileSize.width * multiplier
    elseif direction == Directions.South then
      pos.y = pos.y - mapOverlayData.tileSize.height * multiplier
    elseif direction == Directions.West then
      pos.x = pos.x + mapOverlayData.tileSize.width * multiplier
    end

    creature:setPhantom(true)
    creature:setOutfit(playerOutfit)
    creature:setDirection(direction)
    creature:setOpacity(cloneOpacityStep * i)
    creature:setPosition(pos)
    creature:setWidth(cloneWidth)
    creature:setHeight(cloneHeight)

    creature:show()

    ::continue::
  end

  -- Show the overlay
  cseQ6OverlayWindow:show()
end



-- Handle the custom spell effect's extended opcode
local function onExtendedOpcodeCustomSpellEffect(protocol, opcode, buffer)
  -- Get all the parameters
  local tokens = split(buffer, ';')

  -- If empty, nothing to do
  if #tokens == 0 then
    return
  end

  -- Get the spell id and initialize the spell's parameters
  local spell = tokens[1]
  local params = {}

  -- If there are more tokens, use them as spell's parameters
  if #tokens > 1 then
    params = { unpack(tokens, 2) }
  end

  -- Handle the custom spell for question 6
  if spell == 'q6' then
    -- Initialize parameters as nil
    local direction = nil
    local amountTeleported = nil
    local duration = nil

    -- If parameters are present, use them as numbers
    if #params == 3 then
      direction = tonumber(params[1])
      amountTeleported = tonumber(params[2])
      duration = tonumber(params[3])
    end

    -- Validate direction and fallback to player's direction
    if direction == nil then
      local player = g_game.getLocalPlayer()

      direction = player:getDirection()
    end

    -- Validate amountTeleported and fallback to 0
    if amountTeleported == nil then
      amountTeleported = 0
    end

    -- Validate duration and fallback to 1000
    if duration == nil then
      duration = 1000
    end

    -- Call the spell's effect's handler
    q6SpellEffect(direction, amountTeleported, duration)
  end
end



-- Initialize the module
function init()
  -- Register the custom spell effect's extended opcode
  ProtocolGame.registerExtendedOpcode(EXTENDED_OPCODE_CUSTOM_SPELL_EFFECT, onExtendedOpcodeCustomSpellEffect)

  -- Create the overlay window
  local gameMapPanel = modules.game_interface.getMapPanel()

  cseQ6OverlayWindow = g_ui.createWidget('UIWindow', gameMapPanel)

  -- If succeded, set its properties, create the creatures' widgets and hide
  -- everything
  if cseQ6OverlayWindow ~= nil then
    cseQ6OverlayWindow:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    cseQ6OverlayWindow:addAnchor(AnchorRight, 'parent', AnchorRight)
    cseQ6OverlayWindow:addAnchor(AnchorTop, 'parent', AnchorTop)
    cseQ6OverlayWindow:addAnchor(AnchorBottom, 'parent', AnchorBottom)

    cseQ6OverlayWindow:setPhantom(true)

    cseQ6OverlayWindow:hide()
  end
end



-- Terminate the module
function terminate()
  -- Unegister the custom spell effect's extended opcode
  ProtocolGame.unregisterExtendedOpcode(EXTENDED_OPCODE_CUSTOM_SPELL_EFFECT)

  -- If overlay exists, destroy its children and itself
  if cseQ6OverlayWindow ~= nil then
    q6DestroyOverlayChildren()

    cseQ6OverlayWindow:destroy()
  end
end
