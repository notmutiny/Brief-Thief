BriefThief={
	ver=2,
	color="", -- current string color
	debug=nil, -- makes mutinys life easier
	slash="", -- current slash command
	guard=nil, -- display on guards ?
	gstring="", -- guard settings option
	fence=nil, -- display on fences ?
	fstring="", -- fence settings option
	clemency=nil, -- display clemency timer ?
	defaultPersistentSettings={
		color="orange",
		debug=false,
		slash="/loot",
		guard=true,
		gstring="when arrested",
		fence=true,
		fstring="when selling",
		clemency=true
	},
	persistentSettings={},
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
		gray="|c888888"
	},    
}

local brtf=BriefThief

-- Initialize --
function BriefThief:Initialize()
	self.persistentSettings=ZO_SavedVars:NewAccountWide("BriefThiefVars",self.ver,nil,self.defaultPersistentSettings) -- load in the persistent settings
	self.color=self.persistentSettings.color -- set our current color to whatever came from the settings file
	self.slash=self.persistentSettings.slash -- sets our slash command
	self.guard=self.persistentSettings.guard -- sets briefthief to guard settings
	self.gstring=self.persistentSettings.gstring -- loads gstring for future perving
	self.fence=self.persistentSettings.fence -- sets briefthief to fence settings
	self.fstring=self.persistentSettings.fstring -- sets fence settings string 
	self.debug=self.persistentSettings.debug -- sets briefthief to debug settings
	self.clemency=self.persistentSettings.clemency -- sets briefthief to clemency settings
    ZO_CreateStringId("SI_BINDING_NAME_CHECK_LOOT","Check Loot")
	EVENT_MANAGER:UnregisterForEvent("BriefThief_OnLoaded",EVENT_ADD_ON_LOADED)
	brtf:CreateSettings() -- very delicate do not derp inside func()
end

-- Convienence --
function BriefThief:GetInventory()
    return PLAYER_INVENTORY.inventories[INVENTORY_BACKPACK].slots
end

function BriefThief:Chat(msg)
    d(self.colors[self.color]..msg)
end

-- Addon --
function BriefThief:Check(who)
    local StolenNumber,StolenValue,Inventory=0,0,self:GetInventory()
	local bonus=( ZO_Fence_Manager:GetHagglingBonus()/100 ) + 1 -- adds haggling perk bonus to total
    for key,item in pairs(Inventory)do
        if(item.stolen)then
            StolenNumber=StolenNumber+item.stackCount
            local StackValue=item.sellPrice*item.stackCount
            StolenValue=StolenValue+StackValue
        end
    end	
	local plural,sclem,timer="s",nil,GetTimeToClemencyResetInSeconds() -- plural string, clemency print string, timer adds clemency data as total seconds
    if(StolenNumber==1) then plural="" end -- mandatory string ocd
	if(self.clemency and timer ~= 0) then sclem="  -  "..(math.floor(timer/3600)).."h "..(math.ceil(timer%3600/60)).."m clemency cooldown" else sclem="" end -- string clemency
 	if(who=="fence" and fcache==math.ceil(StolenValue*bonus)) then return else self:Chat(tostring(StolenNumber).." stolen item"..plural.." worth "..tostring(math.ceil(StolenValue*bonus)).." gold"..sclem.." |r") end
	if(who=="fence") then fcache=math.ceil(StolenValue*bonus) end -- if check came from fence then we save total value to fence cache
	if(self.debug) then self:Chat(self.slash.." - clem ["..tostring(self.clemency).."] - guards "..self.gstring:lower().." ["..tostring(self.guard).."] - fence "..self.fstring:lower().." ["..ZO_Fence_Manager:GetHagglingBonus().."] ["..tostring(self.fence).."] ["..tostring(fcache).."]") end
end -- mutiny thinks he did the math correctly but he retook algebra twice so who can be sure

function BriefThief:ToggleEvent(who) -- this controls /loot (event)
	local snot,ecache,sevent,scache=nil,nil,nil,nil -- string not not snot, event cache, event string, settings string cache
	if (who=="guard") then
		if self.guard then snot=" not " else snot=" " end
	    self.guard=not self.guard -- flips boolean
		self.persistentSettings.guard=self.guard -- saves to memory
		if self.guard then self.gstring="when arrested" self.persistentSettings.gstring=self.gstring
		else self.gstring="disabled" self.persistentSettings.gstring=self.gstring end
		scache,ecache=self.gstring,self.guard
	elseif (who=="fence") then
		if self.fence then snot=" not " else snot=" "end
	    self.fence=not self.fence
		self.persistentSettings.fence=self.fence
		if self.fence then self.fstring="when selling" self.persistentSettings.fstring=self.fstring
		else self.fstring="disabled" self.persistentSettings.fstring=self.fstring end
		scache,ecache=self.fstring,self.fence
	elseif (who=="clem" or who=="clemency") then
		if self.clemency then snot=" not " else snot=" " end
	    self.clemency=not self.clemency
		self.persistentSettings.clemency=self.clemency
		scache,ecache="",self.clemency
	end
	if (who=="clem" or who=="clemency") then sevent="show clemency cooldown timer" else sevent="show when talking to "..who.."s" end
	self:Chat("Brief Thief will"..snot..sevent)
	if self.debug then self:Chat("Brief Thief set "..who.." to show "..scache.." ["..tostring(ecache).."]") end
--	CALLBACK_MANAGER:FireCallbacks("LAM-RefreshPanel", panel) -- need to figure out how to get this to werk so legacy chat updates settings panel
end

-- Settings --
function BriefThief:ChangeColor(color,where)
	local newColor=color:lower() -- make the command case-insensitive
	if not(self.colors[newColor])then return end -- if the word they typed isn't a color we support then fuck em
	if(newColor==self.color)then return end -- if we're already that color then fuck em
	local OldHex,NewHex=self.colors[self.color],self.colors[newColor]
	self.color=newColor
	self.persistentSettings.color=self.color -- save the setting in ESO settings file
	if (where=="chat" or self.debug) then brtf:Chat("Brief Thief changed color to "..newColor) end
end

function BriefThief:PersistentCommand(cmd,who)
    if who=="loot" then 
		if self.slash ~="/loot" then return end
    elseif who=="thief" then
		if self.slash ~="/thief" then return end
    else return end
    if(cmd=="guard" or cmd=="fence") then brtf:ToggleEvent(cmd)
    elseif (cmd=="clem" or cmd=="clemency") then brtf:ToggleEvent(cmd)
	elseif (cmd=="DEBUG") then -- for when mutiny breaks something
		local sdebug=nil if brtf.debug then sdebug="|cff0000 disabled" else sdebug="|c00ff00 enabled" end
		d(brtf.colors[brtf.color].."Brief Thief|r"..brtf.colors.yellow.." debug mode|r"..sdebug.."|r")
		brtf.debug=not brtf.debug
		brtf.persistentSettings.debug=brtf.debug
    elseif (cmd and cmd~="") then brtf:ChangeColor(cmd,"chat")
    else brtf:Check() end
end

function BriefThief:UpdateClemency(value)
	self.clemency=value
	self.persistentSettings.clemency=self.clemency
	if self.debug then self:Chat("Brief Thief set show clemency to "..tostring(self.clemency)) end
end

function BriefThief:CommandSettings(value)
    self.slash=value
    self.persistentSettings.slash=self.slash
    if self.debug then self:Chat("Brief Thief set slash command to "..value) end
end

function BriefThief:SaveSettings(what,who)
	if who=="guard" then
		self.gstring=what
		self.persistentSettings.gstring=self.gstring
		if self.gstring=="when arrested" then self.guard=true
		else self.guard=false end
		self.persistentSettings.guard=self.guard
		if self.debug then self:Chat("Brief Thief set "..who.." to show "..self.gstring.." ["..tostring(self.guard).."]") end
	elseif who=="fence" then
		self.fstring=what
		self.persistentSettings.fstring=self.fstring
		if self.fstring=="when selling" then self.fence=true
		else self.fence=false end
		self.persistentSettings.fence=self.fence
		if self.debug then self:Chat("Brief Thief set show "..who.." to show "..self.fstring.." ["..tostring(self.fence).."]") end
	end
end

function BriefThief:PersistantHooks(who) -- only way mutiny could figure out to "disable" events between sessions
    if (who=="guard") and (self.guard) then brtf:Check()
    elseif (who=="fence") and (self.fence) then brtf:Check(who)
	end -- I may not be good at coding but I am good at leaving things lost and confused
end

function BriefThief_CheckLoot() -- required for keybind
	brtf:Check()
end

function BriefThief:CreateSettings()
    local LAM=LibStub("LibAddonMenu-2.0")
    local defaultSettings={}
    local panelData = {
	    type = "panel",
	    name = "Brief Thief",
	    displayName = self.colors[self.color].."Brief Thief",
	    author = "mutiny and Jackarunda",
        version = tostring(self.ver),
		registerForDefaults = true,
    	registerForRefresh = true,
        slashCommand = "/briefthief"
    }
    local optionsData = {
        [1] = {
            type = "header", -- DISPLAY SETTINGS
            name = self.colors[self.color].."Display|r settings",
            width = "full",
            },
         [2] = {
            type = "checkbox", 
            name = " Show clemency skill cooldown",
            width = "half",
            getFunc = function() return self.clemency end,
            setFunc = function(value) self:UpdateClemency(value) end,
            },
         [3] = {
            type = "dropdown",
            name = "Message color",
            choices = {"red","green","blue","cyan","magenta","yellow","orange","purple","pink","brown","white","gray"},
            width = "half",
            getFunc = function() return self.color end,
            setFunc = function(value) self:ChangeColor(value) end,
            },
         [4] = {
            type = "header", -- START THIEF SETTINGS --
            name = self.colors[self.color].."Thief|r settings",
            width = "full",
            },
        [5] = {
            type = "dropdown",
            name = " Slash command",
            choices = {"/loot","/thief"},
			warning ="Using legacy chat commands to modify |cffdb00any|r options without using the settings panel will require ReloadUI to refresh selected settings",
			width = "full",
            getFunc = function() return self.slash end,
            setFunc = function(value) self:CommandSettings(value) end,
            },
        [6] = {
            type = "divider",
            width = "full",           
            },
		[7] = {
            type = "description",
            text = " Adjust when Brief Thief shows information. Save keybind in control settings.",
            width = "full",           
            },
        [8] = {
            type = "divider",
            width = "full",           
            },
         [9] = {
            type = "dropdown",
            name = " Show on guards",
            choices = {"when arrested","disabled"},
			width = "full",
            getFunc = function() return self.gstring end,
            setFunc = function(value) brtf:SaveSettings(value,"guard") end,
            },
         [10] = {
            type = "dropdown",
            name = " Show on fences",
            choices = {"when selling","disabled"},
            width = "full",
            getFunc = function() return self.fstring end,
            setFunc = function(value) brtf:SaveSettings(value,"fence") end,
            },
         [11] = {
            type = "submenu", -- START ABOUT MESSAGE --
            name = "About message",
            width = "full",
			controls= {
				[1] = {
					type = "description",
					text = " More features planned, just have to find time to impliment them.",
					width = "full",           
					},
				[2] = {
					type = "description",
					text = " I am an amateur hobby dev so work is slow in addition to learning.",
					width = "full",           
					},
				[3] = {
					type = "description",
					text = " Keep up with development : |cffdb00https://github.com/mutenous/Brief-Thief|r",
					width = "full",           
					},
				[4] = {
					type = "description",
					text = " Thank you for understanding and using Brief Thief ver "..tostring(self.ver)..". ツ",
					width = "full",           
            		}
			}
    } }
    LAM:RegisterOptionControls("BriefThief", optionsData)
	LAM:RegisterAddonPanel("BriefThief", panelData)
end
-- Game hooks --
SLASH_COMMANDS["/loot"]=function(cmd) brtf:PersistentCommand(cmd, "loot") end
SLASH_COMMANDS["/thief"]=function(cmd) brtf:PersistentCommand(cmd, "thief") end

SLASH_COMMANDS["//"]=function() if brtf.debug then ReloadUI() end end

EVENT_MANAGER:RegisterForEvent("BriefThief_OpenFence",EVENT_OPEN_FENCE,function() brtf:PersistantHooks("fence") end)
EVENT_MANAGER:RegisterForEvent("BriefThief_ArrestCheck",EVENT_JUSTICE_BEING_ARRESTED,function() brtf:PersistantHooks("guard") end)
EVENT_MANAGER:RegisterForEvent("BriefThief_OnLoaded",EVENT_ADD_ON_LOADED,function() BriefThief:Initialize() end)