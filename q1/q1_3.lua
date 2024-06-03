--[[
  Since player can be logged in when the timer hits, let's be extra safe and
  check if the player is online to release storage in a more proper way. For
  this, we need to pass the player's name and GUID along the storageId

  The database operation can fail and lead to undesired behaviors
]]



-- Release storageId for the given player
-- If playerGuid is less than 1, nothing to do, because characters starts at 1
-- in the database
-- If storageId is negative here, there is nothing to do because in C++ it is
-- handled as uint32_t. So, let's avoid it
local function releaseStorage(playerName, playerGuid, storageId)
  -- Validate arguments
  if type(playerName) ~= 'string' or type(playerGuid) ~= 'number' or type(storageId) ~= 'number' then
    return
  end

  if #playerName == 0 or playerGuid < 1 or storageId < 0 then
    return
  end

  -- Try to get the player by name
  local player = Player(playerName)

  -- If player was found and online, release it from the player's object.
  -- Otherwise, try to release directly in database
  if player ~= nil then
    player:setStorageValue(storageId, -1)
  else
    -- Base query
    local sql = [[
      DELETE FROM
        `player_storage`
      WHERE
        `player_id` = %d AND
        `key` = %d
    ]]

    -- Prepare the query
    local preparedSQL = string.format(
      sql,
      playerGuid,
      storageId
    )

    -- Execute the query
    db.query(preparedSQL)
  end
end



-- Event fired on user logout, before saving it to database
function onLogout(player)
  if player:getStorageValue(1000) == 1 then
    addEvent(releaseStorage, 1000, player:getName(), player:getGuid(), 1000)
  end

  return true
end
