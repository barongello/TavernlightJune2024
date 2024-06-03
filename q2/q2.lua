-- Print the name of guilds with less than memberCount members in ascending
-- alphabetical order
-- memberCount can't be less than 2, otherwise it would try to fetch guilds with
-- 0 members, which does not exist
function printSmallGuildNames(memberCount)
  -- Validate memberCount
  if type(memberCount) ~= 'number' or memberCount < 2 then
    return
  end

  -- Base query
  local sql = [[
    SELECT
      `g`.`name` AS `guild_name`,
      COUNT(`gm`.`player_id`) AS `member_count`
    FROM
      `guilds` AS `g`
      INNER JOIN
        `guild_membership` AS `gm`
      ON
        `gm`.`guild_id` = `g`.`id`
    GROUP BY
      `g`.`id`
    HAVING
      `member_count` < %d
    ORDER BY
      `guild_name` ASC;
  ]]

  -- Prepare query and execute it
  local preparedSql = string.format(sql, memberCount)
  local resultId = db.storeQuery(preparedSql)

  -- If anything went wrong or the result is empty, nothing to do
  if resultId == false then
    return
  end

  -- Iterate over the results and print guild names
  repeat
    local guildName = result.getString(resultId, 'guild_name')

    print(guildName)
  until not result.next(resultId)

  -- Clean up the query's result
  result.free(resultId)
end
