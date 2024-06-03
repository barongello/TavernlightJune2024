--[[
  Since player will no longer be valid when the releaseStorage is called from
  addEvent's callback, let's pass the player's guid and storageId to it and deal
  directly with the database

  Not the best option, since here we have a race condition: maybe, when the
  releaseStorage is called, the player's object still in memory and being saved
  by the server, which would re-add the previous value to the database

  Also the database operation can fail and not release the storage, or player
  logged back in before the callback fires and then the value was re-read into
  player's object in memory... Things that can lead to undesired behaviors
]]



-- Release storageId for the given player
-- If playerGuid is less than 1, nothing to do, because characters starts at 1
-- in the database
-- If storageId is negative here, there is nothing to do because in C++ it is
-- handled as uint32_t. So, let's avoid it
local function releaseStorage(playerGuid, storageId)
  -- Validate arguments
  if type(playerGuid) ~= 'number' or type(storageId) ~= 'number' then
    return
  end

  if playerGuid < 1 or storageId < 0 then
    return
  end

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



-- Event fired on user logout, before saving it to database
function onLogout(player)
  if player:getStorageValue(1000) == 1 then
    addEvent(releaseStorage, 1000, player:getGuid(), 1000)
  end

  return true
end
