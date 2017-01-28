-- Global table
BriefThief={
	version=1.1,
	colors={ 				-- this is what i'd call data-driven
		red="|cff0000", 	-- all you gotta do to add new colors is just add entries to the table
		green="|c00ff00", 	-- no if elseif polling, no changing code
		blue="|c0000ff",
		
		cyan="|c00ffff",
		magenta="c|ff00ff",
		yellow="|cffff00",
		
		orange="|cffa700",
		purple="|c8800aa",
		pink="|cffaabb",
		brown="|c554400",
		
		white="|cffffff",
		black="|c000000",
		gray="|c888888"
	},
	curColor="",
	prevColor="",
	defaultPersistentSettings={
		color="orange"
	},
	persistentSettings={}
}

-- Convienence functions
local function TableLength(tab)
	if not(tab) then return 0 end
	local Result=0
	for key,value in pairs(tab)do
		Result=Result+1
	end
	return Result
end

local function ShowAllItemInfo(item)
    for key,attribute in pairs(item)do
        d(tostring(i).." : "..tostring(j))
    end
end

-- Addon member vars
function BriefThief:Initialize()
	self.persistentSettings=ZO_SavedVars:NewAccountWide("BriefThiefVars",self.version,nil,self.defaultPersistentSettings) -- load in the persistent settings
	self.curColor=self.persistentSettings.color -- set our current color to whatever came from the settings file
	EVENT_MANAGER:UnregisterForEvent("BriefThief_OnLoaded",EVENT_ADD_ON_LOADED) -- not really sure if we have to do this
end

function BriefThief:ChangeColor(color)
	local newColor=color:lower() -- make the command case-insensitive
	if not(self.colors[newColor])then return end -- if the word they typed isn't a color we support then fuck em
	if(newColor==self.curColor)then return end -- if we're already that color then fuck em
	local OldHex,NewHex=self.colors[self.curColor],self.colors[newColor]
	d(OldHex.."Brief Thief has changed color from "..self.curColor.." to "..NewHex..newColor..OldHex.."!|r")
	self.prevColor=self.curColor
	self.curColor=newColor
	self.persistentSettings.color=self.curColor -- save the setting in ESO settings file
end

function BriefThief:Chat(msg)
	d(self.colors[self.curColor]..""..msg.."|r")
end

function BriefThief:GetInventory()
    return PLAYER_INVENTORY.inventories[INVENTORY_BACKPACK].slots
end

function BriefThief:Check()
    local StolenNumber,StolenValue,Inventory=0,0,self:GetInventory()
    for key,item in pairs(Inventory)do
        if(item.stolen)then
            StolenNumber=StolenNumber+item.stackCount
            local StackValue=item.sellPrice*item.stackCount
            StolenValue=StolenValue+StackValue
        end
    end
    local plural="s"
    if(StolenNumber==1)then plural="" end
    self:Chat(tostring(StolenNumber).." stolen item"..plural.." worth "..tostring(StolenValue).." gold")
end

-- Game hooks
SLASH_COMMANDS["/loot"]=function(arg) 
    if ((arg) and (arg~="")) then
    BriefThief:ChangeColor(arg)
    else BriefThief:Check()
    end
end

EVENT_MANAGER:RegisterForEvent("BriefThief_ArrestCheck",EVENT_JUSTICE_BEING_ARRESTED,function() BriefThief:Check() end)
EVENT_MANAGER:RegisterForEvent("BriefThief_OnLoaded",EVENT_ADD_ON_LOADED,function() BriefThief:Initialize() end)

-- Reference
-- self.savedVariables = ZO_SavedVars:New("BriefThiefVars", self.version, nil, self.Default)
-- EVENT_MANAGER:UnregisterForEvent(self.name,EVENT_ADD_ON_LOADED)
