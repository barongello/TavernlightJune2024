-- Remove member (by name) from player's (by id) party
-- This does not check if the player is the party leader, neither if trying to
-- remove the party leader, neither if player is trying to remove itself
function removeMemberFromPlayerParty(playerId, memberName)
  -- Get player by ID
  local player = Player(playerId)

  -- If player not found, nothing to do
  if player == nil then
    return
  end

  -- Get the player's party
  local party = player:getParty()

  -- If not in party, nothing to do
  if party == nil then
    return
  end

  -- Get target member by name
  local targetMember = Player(memberName)

  -- If target member not found, nothing to do
  if targetMember == nil then
    return
  end

  -- Check if target member is in party and, if it is, try to remove it
  for _, partyMember in pairs(party:getMembers()) do
    if partyMember == targetMember then
      party:removeMember(targetMember)

      return
    end
  end
end
