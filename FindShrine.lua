-- Global table --
FindShrine={
	ver=0.1,
	loc=nil
}

local find = FindShrine

-- Initialize function --
function FindShrine:Initialize()
	EVENT_MANAGER:UnregisterForEvent("FindShrine_OnLoaded",EVENT_ADD_ON_LOADED)
end

-- Convienence functions --
function FindShrine:CurrentLoc() -- finds your current zone
    self.loc = GetPlayerLocationName() -- saves to variable
end

-- Addon variables --
function FindShrine:StartTeleport()
	local guild=3 -- determines which guild # we scan (temp to get it workin)
	local n = GetNumGuildMembers(guild) -- checks how many players are in that guild
	for i=1,n do -- loops 1 to total number of guild members (can set it to online members for further optimization)
		local name,note,rankIndex,playerStatus,secsSinceLogoff = GetGuildMemberInfo(guild,i) -- saves all character data for that slot
		if playerStatus ~= PLAYER_STATUS_OFFLINE then d(name) end -- print name if they are online (temp debug use)
	end
end

-- Game hooks --
SLASH_COMMANDS["/home"]=function() FindShrine:StartTeleport() end -- gonna bind that to a configurable key
SLASH_COMMANDS["//"]=function() ReloadUI() end -- fast /reloadui for mutiny

EVENT_MANAGER:RegisterForEvent("FindShrine_OnLoaded",EVENT_ADD_ON_LOADED,function() find:Initialize() end)

-- Saved snips --
--[[local numGuild = GetNumGuilds() -- saves how many guilds we are in -- saved for later
]]--