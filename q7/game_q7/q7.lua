-- Configurations
local JUMP_BUTTON_AUTO_MOVE_TIMEOUT = 100
local JUMP_BUTTON_STEP_X            = 10
local JUMP_BUTTON_SPACING_X         = 10
local JUMP_BUTTON_SPACING_TOP       = 30
local JUMP_BUTTON_SPACING_BOTTOM    = 10



-- References
local q7Window = nil
local q7Button = nil
local jumpButton = nil



-- Events
local autoMoveEvent = nil



-- Run on game start
function online()
  -- If trigger button is found, show it
  if q7Button ~= nil then
    q7Button:show()
  end
end



-- Run on game end
function offline()
  resetWindow()
end



-- Module initialization on load
function init()
  -- Connect the signals/callbacks
  connect(g_game, {
    onGameStart = online,
    onGameEnd = offline
  })

  -- Create the window, get its reference and hide it
  q7Window = g_ui.displayUI('q7', modules.game_interface.getRightPanel())

  -- If window is found, hide it
  if q7Window ~= nil then
    q7Window:hide()
  end

  -- Create the trigger button, get its reference and set it as not toggled
  q7Button = modules.client_topmenu.addRightGameToggleButton('q7Button', tr('Q7'), '/images/topbuttons/q7', toggle)

  -- If trigger button is found, set its toggle state to off
  if q7Button ~= nil then
    q7Button:setOn(false)
  end

  -- Get the reference to the jumpButton
  jumpButton = q7Window:getChildById('jumpButton')

  -- If initialized after game started, call the callback manually
  if g_game.isOnline() then
    online()
  end
end



-- Module termination on unload
function terminate()
  -- Remove the signals/callbacks
  disconnect(g_game, {
    onGameStart = online,
    onGameEnd = offline
  })

  -- Reset window
  resetWindow()

  -- If window is found, destroy it
  if q7Window ~= nil then
    q7Window:destroy()

    q7Window = nil
  end

  -- If trigger button is found, destroy it
  if q7Button ~= nil then
    q7Button:destroy()

    q7Button = nil
  end
end



-- Toggle function of the trigger button
function toggle()
  -- If q7Button is not found, this should not have been called
  if q7Button == nil then
    return
  end

  -- If the toggle button is on, stop window. Otherwise, start it
  if q7Button:isOn() then
    resetWindow()
  else
    startWindow()
  end
end



-- Start window and button states
function startWindow()
  -- If window, trigger button or jump button can't be found, nothing to do
  if q7Window == nil or q7Button == nil then
    return
  end

  -- Toggle on
  q7Button:setOn(true)

  -- Show window, bring it to front and focus it
  q7Window:show()
  q7Window:raise()
  q7Window:focus()

  -- Randomize jumpButton start position
  jumpButtonClick()

  -- Set the timer to auto move the jumpButton
  autoMoveEvent = cycleEvent(jumpButtonAutoMove, JUMP_BUTTON_AUTO_MOVE_TIMEOUT)
end



-- Reset window and trigger button states
function resetWindow()
  -- If there is a cycle event, remove it
  if autoMoveEvent ~= nil then
    removeEvent(autoMoveEvent)

    autoMoveEvent = nil
  end

  -- If q7Window is found, hide it
  if q7Window ~= nil then
    q7Window:hide()
  end

  -- If q7Button is found, set its toggle state to off
  if q7Button ~= nil then
    q7Button:setOn(false)
  end
end



-- Send jumpButton back to the right side
function resetJumpButtonX()
  -- If window or jump button couldn't be find, nothing to do
  if q7Window == nil or jumpButton == nil then
    return
  end

  -- Get window and jump button current position
  windowPos = q7Window:getPosition()
  buttonPos = jumpButton:getPosition()

  -- Calculate the new jump button X position based on window position and size and jump button size
  buttonPos.x = windowPos.x + q7Window:getWidth() - jumpButton:getWidth() - JUMP_BUTTON_SPACING_X

  -- Set the jump button new position
  jumpButton:setPosition(buttonPos)
end



-- Send jumpButton to a random Y position
function resetJumpButtonY()
  -- If window or jump button couldn't be find, nothing to do
  if q7Window == nil or jumpButton == nil then
    return
  end

  -- Get window and jump button current position
  windowPos = q7Window:getPosition()
  buttonPos = jumpButton:getPosition()

  -- Get the maximum Y that the jump button can have and randomize it
  local maxY = q7Window:getHeight() - jumpButton:getHeight() - JUMP_BUTTON_SPACING_BOTTOM
  local randomY = math.random(JUMP_BUTTON_SPACING_TOP, maxY)

  -- Calculate the new jump button Y position based on window position and randomized Y
  buttonPos.y = windowPos.y + randomY

  -- Set the jump button new position
  jumpButton:setPosition(buttonPos)
end



-- Auto move jumpButton horizontaly
function jumpButtonAutoMove()
  -- If window or jump button couldn't be find, nothing to do
  if q7Window == nil or jumpButton == nil then
    return
  end

  -- Get window and jump button current position
  windowPos = q7Window:getPosition()
  buttonPos = jumpButton:getPosition()

  -- Calculate jump button new X position based on its velocity
  buttonPos.x = buttonPos.x - JUMP_BUTTON_STEP_X

  -- If hit the left side, send it back to right side and randomizes its Y
  -- position
  if buttonPos.x <= windowPos.x + JUMP_BUTTON_SPACING_X then
    resetJumpButtonX()
    resetJumpButtonY()

    return
  end

  -- Set the jump button new position
  jumpButton:setPosition(buttonPos)
end



-- On click jumpButton, send it back to right side and randomize Y position
function jumpButtonClick()
  -- If jump button can't be found, nothing to do
  if jumpButton == nil then
    return
  end

  -- Reset jump button X position
  resetJumpButtonX()

  -- Randomize jump button Y position
  resetJumpButtonY()
end
