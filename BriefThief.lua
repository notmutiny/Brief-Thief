-- Global table
BriefThief={
    ver=1.8,
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
    showGuard=true,
    showFence=true,
	showRemind=true,
	defaultPersistentSettings={
		color="orange",
		guard=true,
		fence=true,
		remind=true
	},
	persistentSettings={}
}

local brtf = BriefThief

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

-- Addon member variables
function BriefThief:Help() -- the following function builds the text box help menu
	local c,y,d=brtf.colors[brtf.curColor],brtf.colors.yellow,"  - -|r"
	self:Chat("- -|r"..y..d..c..d..y..d..c..d..y..d..c.."  Brief Thief "..brtf.ver.." help|r"..y..d..c..d..y..d..c..d..y..d..c..d)
	self:Chat("/ loot  echo "..y.." - |r"..c.." / loot  fence "..y.." - |r"..c.." / loot  guard "..y.." - |r"..c.." / loot  (color)")
	self:Chat("Check updates:|r"..y.."  http://github.com/mutenous/Brief-Thief|r")
	self:Chat("- -|r"..y..d..c..d..y..d..c..d..y..d..c..d..y.."  -"..c..d..y.."  -  -|r"..c..d..y.."  -"..c..d..y..d..c..d..y..d..c..d..y..d..c..d)
end

function BriefThief:Echo() -- coming soon, focused on recode not adds
	self:Chat("temporary string|r")
end

function BriefThief:Initialize()
	self.persistentSettings=ZO_SavedVars:NewAccountWide("BriefThiefVars",self.ver,nil,self.defaultPersistentSettings) -- load in the persistent settings
	self.curColor=self.persistentSettings.color -- set our current color to whatever came from the settings file
	self.showGuard=self.persistentSettings.guard -- sets briefthief to guard settings
	self.showRemind=self.persistentSettings.remind -- sets briefthief to guard settings
	self.showFence=self.persistentSettings.fence -- sets briefthief to fence settings
	EVENT_MANAGER:UnregisterForEvent("BriefThief_OnLoaded",EVENT_ADD_ON_LOADED) -- not really sure if we have to do this
end

function BriefThief:ChangeColor(color)
	local newColor=color:lower() -- make the command case-insensitive
	if not(self.colors[newColor])then return end -- if the word they typed isn't a color we support then fuck em
	if(newColor==self.curColor)then return end -- if we're already that color then fuck em
	local OldHex,NewHex=self.colors[self.curColor],self.colors[newColor]
	d(OldHex.."Brief Thief has changed to "..NewHex..newColor)
	self.prevColor=self.curColor
	self.curColor=newColor
	self.persistentSettings.color=self.curColor -- save the setting in ESO settings file
end

function BriefThief:Chat(msg)
    d(self.colors[self.curColor]..msg.."|r")
end

function BriefThief:GetInventory()
    return PLAYER_INVENTORY.inventories[INVENTORY_BACKPACK].slots
end

function BriefThief:Check()
    local StolenNumber,StolenValue,Inventory=0,0,self:GetInventory()
	local bonus=( ZO_Fence_Manager:GetHagglingBonus() / 100 ) + 1
    for key,item in pairs(Inventory)do
        if(item.stolen)then
            StolenNumber=StolenNumber+item.stackCount
            local StackValue=item.sellPrice*item.stackCount
            StolenValue=StolenValue+StackValue
        end
    end
    local plural="s"
    if(StolenNumber==1)then plural="" end
	self:Chat(tostring(StolenNumber).." stolen item"..plural.." worth "..tostring(math.floor(StolenValue*bonus)).." gold")
end

function BriefThief:ToggleEvent(who) -- this controls /loot (event)
    if (who=="guard") then
        if (brtf.showGuard) then
            self:Chat("Brief Thief will not show when talking to "..who.."s|r")
	    	self.showGuard=not self.showGuard -- flips boolean
	    	self.persistentSettings.guard=self.showGuard -- saves to memory
        else
            self:Chat("Brief Thief will show when talking to "..who.."s|r")
	    	self.showGuard=not self.showGuard -- there must be a way to clean this
	    	self.persistentSettings.guard=self.showGuard
        end
    elseif (who=="fence") then
        if (self.showFence) then
            self:Chat("Brief Thief will not show when talking to "..who.."s|r")
	    	self.showFence=not self.showFence
	    	self.persistentSettings.fence=self.showFence
        else
            self:Chat("Brief Thief will show when talking to "..who.."s|r")
	    	self.showFence=not self.showFence
	    	self.persistentSettings.fence=self.showFence
        end
    end
end

function BriefThief:PersistantHooks(who) -- only way mutiny could figure out to "disable" events between sessions
    if (who=="guard") and (self.showGuard) then brtf:Check()
    elseif (who=="fence") and (self.showFence) then brtf:Check()
	end -- I may not be good at coding but I am good at leaving things lost and confused
end

-- Game hooks
SLASH_COMMANDS["/loot"]=function(cmd)
    if(cmd=="guard" or cmd=="fence") then brtf:ToggleEvent(cmd)
    elseif (cmd=="help") then brtf:Help()
    elseif (cmd=="echo") then brtf:Echo()
    elseif ((cmd) and (cmd~="")) then brtf:ChangeColor(cmd)
    else brtf:Check() end
end

EVENT_MANAGER:RegisterForEvent("BriefThief_OpenFence",EVENT_OPEN_FENCE,function() brtf:PersistantHooks("fence") end)
EVENT_MANAGER:RegisterForEvent("BriefThief_ArrestCheck",EVENT_JUSTICE_BEING_ARRESTED,function() brtf:PersistantHooks("guard") end)
EVENT_MANAGER:RegisterForEvent("BriefThief_OnLoaded",EVENT_ADD_ON_LOADED,function() brtf:Initialize() end)