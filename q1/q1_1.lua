--[[
  Since player will no longer be valid when the releaseStorage is called from
  addEvent's callback, simply set the storage's value to -1 right on the
  onLogout function

  Also make releaseStorage more generic and add validations
]]



-- Release storageId for the given player
-- If storageId is negative here, it will be wrapped in C++ because it is
-- handled as uint32_t. So, let's avoid it
local function releaseStorage(player, storageId)
  -- Validate arguments
  if type(player) ~= 'userdata' or type(storageId) ~= 'number' then
    return
  end

  if storageId < 0 then
    return
  end

  -- Release storage's slot
  player:setStorageValue(storageId, -1)
end



-- Event fired on user logout, before saving it to database
function onLogout(player)
  if player:getStorageValue(1000) == 1 then
    releaseStorage(player, 1000)
  end

  return true
end
