# Tavernlight interview questions

## Disclaimer

All modified and added files for each question are each on its own folder

Some questions I proposed more than one solution and some solutions have comments on the header with explanations on why things were done the way they were done

This document also contains some thoughts and explanations on each question

I am not sure that all approaches here would work in Ravendawn's server and client, then I will be listing here the exact version I used and the changes I made to them. I went for the OTCv8 client because it seems to be the base of the Ravendawn's client

For questions 1-4 I created talk actions on server (!q1 - !q4) to test them. For questions 5 and 6 I created spells on server to test them. For question 7 it is entirely client side

## Software versions

### The Forgotten Server

- URL: https://github.com/otland/forgottenserver
- Branch: 1.4
- Commit: 31d6e85de2a86fb3f0e36c63509fba75b855b8bd

### OTCv8

- URL: https://github.com/OTCv8/otcv8-dev
- Branch: master
- Commit: 3d32139512cc4576b105682c3579f18fe0d534e4

### MySQL

- Version: 8.0.37

### Windows

- Version: 11

### Visual Studio

- Version: 2022 Community

## Questions

### Question 1

This question has more than one solution, depending on what exactly is wanted to be achieved

While inside the `onLogout` function, `player` stills pointing to a valid object in memory and can be directly accessed. But if we use `addEvent` here, it _can_ lead to a race condition, where the event can be fired while the player's object still in memory or not. Maybe the player even logged back in when the event fires. So I proposed the following solutions:

#### q1_1.lua

This one gets rid of the `addEvent` and release the storage right after checking for its desired condition. So here it is safe and guaranteed that `player` still valid and that the change will be reflected in the database and will be loaded correctly next time player logs in

Also made `releaseStorage` function more generic (to release any desired storage's slot) and added some validations to it

#### q1_2.lua

Here I kept the `addEvent`, but instead of dealing with the player's object in memory when the event fires, it modifies data directly into the database

Again, this _can_ lead to some race conditions, where player can be already logged in back and these database's changes will not reflect in the object in memory

Also made `releaseStorage` function more generic (to release any desired storage's slot)

#### q1_3.lua

This one keeps the `addEvent` and, when the event fires, it checks if the player's object is in memory. If it is, commit the change directly to the player's object. If not, then commit the change directly to the database

Also made `releaseStorage` function more generic (to release any desired storage's slot)

#### Conclusion

The problem with accessing the database directly is that the operation can fail due to any reason

Not really a problem because the same can occur in the C++ side when the player's object is persisted on log out/server close

But is something to keep an eye on and that would need, at least, a log entry to not fail silently

### Question 2

This one is pretty straight forward. It does not make much sense to have this function to just print things to the server's console, but I kept it like this, just focusing on the SQL part

This time I used the TFS 1.4 database's scheme. So maybe it differs a little (or a lot) from the Ravendawn's database, but the idea is the same

It joins `guild`'s table with the `guild_membership`'s table (ignoring invites), group results by guild's `id`, count `player_id`s as `member_count` and filter the `member_count` when they are smaller than the `memberCount` argument

It results in a set that contains the `guild_name` and the `member_count` per record, ordered by `guild_name` alphabetically ascending

Then iterates over the records and prints each `guild_name` to the server's console

If the query fails due to any reason, then nothing will be printed. Maybe would be good to add, at least, a log entry to not fail silently

### Question 3

The functions seems to remove a member from a player's party, so I renamed it accordingly to `removeMemberFromPlayerParty`

Added some validations to guarantee that the "caller" and the target are players and are both connected, to check if the "caller" is on a party and to check if the target player is on the party too, before trying to remove it

It does not check if the "caller" is the party leader, neither if the target is the "caller" itself, neither if the "caller" is trying to remove the party leader (which, in this case, would fail silently)

Tried to keep it simple and to not add out of scope stuff, but would be pretty simple to add these validations to ensure the "caller" is the party leader, or that the "caller" and the target are different, or to dismiss the party if the target is the party leader

### Question 4

This one is a bit trickier, that's why I failed previous time I applied. It uses a custom reference counter system (instead of the `std::shared_ptr` and similars)

Inside the function, retrieving the player does not affect its reference counter. But, everytime the function returns (successfully or not), if the player is offline, this pointer should be deleted. If the player is not offline, we should not delete ìt, because the local variable is pointing to an object that keeps being used

The `Item::CreateItem` function, when succeeded, increases the object's reference counter. When this item is added to the player's inbox, we should check if it succeeded through the return value of the `g_game.internalAddItem`

If the item was successfully added (return value equals to `RETURNVALUE_NOERROR`), now it is being referenced by the player's storage, so we should not delete the item's pointer. If it failed, now the item is not useful anymore and should be deleted

### Question 5

Video solution 1: https://youtu.be/Tp0TmncbzV0

Video solution 2: https://youtu.be/eRa9dY9j7nE

This one I have done two different approaches. One that mimics the video, with random ice tornados spawning around the tile where the spell was casted (that is more complex and expensive in terms of server's processing and client/server communication), and another using `Combat` object and effects, which does not have the random spawning (but is simpler and cheaper in terms of server's processing and client/server communication)

For both, spells were created in `spells.xml` in the server, but the spell's range is hardcoded in the source code for `q5_2.lua` (mainly due to the creation of the combat's area)

#### q5_1.lua

Video: https://youtu.be/Tp0TmncbzV0

This one is more beautiful to watch. It gets the spell's range in the `spells.xml` and use it as radius for the effect

The effect itself calculates how much tornados will have and choose random spots around the caster to spawn

If the spot's tile couldn't be get, or if it is not ground, or if it has an immovable object/item, skips it (so it will not spawn on walls, doors, trees, water, etc.)

If the spot is good for it, then schedule an event with a random timer for some nicer visual effects

It makes use of anonymous functions to take advantage of the closure

To use this spell, simply say: question five one

#### q5_2.lua

Video: https://youtu.be/eRa9dY9j7nE

It makes use of the combat's system and object/parameters. It would be possible to create a new type of combat effect to add the randomness of time/spots, but, right out of the box, it spawns tornados in the circle area around the player

It has the type of ice damage just for consistency

To use this spell, simply say: question five two

### Question 6

Video: https://youtu.be/Tqzq6g-VpqU

This was, by far, the most compelx question. The spell required modification in both sides: server and client. Hope I am not overdeliverying here neither doing things out of the scope

The server holds the spell and its parameters (such as range and cooldown, that is also used to lock user's movement while the effect is going on)

On the server side, when the spell is cast, it gets the spell's parameters and calculates the path the player will travel (stopping before obstacles). Then it teleports the player to the final location and sends to the player, through an extended opcode (created for custom spell effects), the spell that was cast along with this spell's parameters (spell's internal name, player's direction on cast, amount of tiles traveled and the cooldown), separated by semicolon

On client side it required a shader (for the red outline around the player) and a module (to process the spell's effect)

The shader was got and adapted from Mehah's client. Just added a `q6_outline_fragment.frag` and a `q6_outline_vertex.frag` to the client's `data\shaders` folder (the vertex one could have been ommited and used the `outfit_default_vertex.frag` when registering the shader, since it is just a copy of it. But, for safety, it has its own file to avoid "bugs", if the `outfit_default_vertex.frag` changes someday for any reason)

To register the shader, modified the `modules\game_shaders\shaders.lua` script and added `g_shaders.createOutfitShader("outfit_outline", "/shaders/q6_outline_vertex", "/shaders/q6_outline_fragment")` to its `init` function

For the module, modified `init.lua` and, after `g_modules.autoLoadModules(9999)`, I just added the `g_modules.ensureModuleLoaded("game_q6")`. Then all the module's files reside inside `modules\game_q6` folder

The module itself is a "custom spell effect handler". It register an extended opcode for the custom spell effects received from the server and handles them accordingly, parsing spell's name and arguments and calling its handler properly

Would be better to do the "dash" effect through shaders, passing the player's current texture to it, including mounts (if allowed) and such (even more if there would be more effects depending on this, it would be nice to edit the shaders' manager to accomodate such situations). Or maybe adding more combat's effects, or attached effects like in Mehah's client

For now, I did it in a hacky way: create an invisible overlay `UIWindow` with some `UICreature`s that shares the player's outfit and direction

Then all positioning and fading is calculated and the `UICreature` is added to the overlay `UIWindow`. The player's movement is locked for the duration of the effect, the outline shader is put in place, then the overlay is shown and we have this nice "The Flash"'s dash effect

When the effect is gone, the outline shader is removed, the `UICreature`s are destroyed and the overlay is hidden

This also does not store the previous player's outfit shader, so it will reset to the default one. Maybe would be good to implement and expose a `getOutfitShader` for situations like this, so we can restore it to the previous outfit shader, instead of setting it to the default one

It makes use of anonymous functions to take advantage of the closure

Hope you like it! Is one of those things where you don't rest in peace while you don't find a solution that fits. I know is is not the best approach and probably not good to release, but is to show off the perseverance, creativity and problem solving skills (which I love)

### Question 7

Video: https://youtu.be/j9-ysaC5GIw

It is a module entirely written in client side. It makes use of the `game_interface` module to be loaded, since it is a GUI window with pure GUI functionality

Modified the `modules\game_interface\interface.otmod` and added the `game_q7` to its `load-later` section

Then added the `game_q7` folder to `modules` folder and a `q7.png` icon to the `data\images\topbuttons` folder

The module makes use of OTUI (with translatable strings) and the code itself adds a toggle button to the top menu, with the `q7.png` as its icon

From here the window's code is pretty straight forward and well documented on `q7.lua` file

## Conclusion

Hope this time I did it better and you people decide to give this "passionate about games and coding" man a chance. We share the same passions ❤️

You won't regret it! I am very proactive, creative, communicative, skilled and passionate about it. The things I don't know, specially about the OT world, I can easily learn through code reading and my colleagues

Thanks for your time
