BriefThief={
	ver=2.1,
	curColor="",
	prevColor="",
	debug=nil,
	showGuard=nil,
	guardString="",
	showFence=nil,
	fenceString="",
	clemency=nil,
	defaultPersistentSettings={
		debug=false,
		color="orange",
		guard=true,
		gstring="when stopped",
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
		black="|c000000",
		gray="|c888888"
	},    
}

local brtf=BriefThief

-- Initialize --
function BriefThief:Initialize()
	self.persistentSettings=ZO_SavedVars:NewAccountWide("BriefThiefVars",self.ver,nil,self.defaultPersistentSettings) -- load in the persistent settings
	self.curColor=self.persistentSettings.color -- set our current color to whatever came from the settings file
	self.showGuard=self.persistentSettings.guard -- sets briefthief to guard settings
	self.guardString=self.persistentSettings.gstring -- saves gstring for future perving
	self.showFence=self.persistentSettings.fence -- sets briefthief to fence settings
	self.fenceString=self.persistentSettings.fstring -- sets fence settings string 
	self.debug=self.persistentSettings.debug -- sets briefthief to debug settings
	self.clemency=self.persistentSettings.clemency -- sets briefthief to clemency settings
	EVENT_MANAGER:UnregisterForEvent("BriefThief_OnLoaded",EVENT_ADD_ON_LOADED)
	brtf:CreateSettings()
end


-- Convienence --
function BriefThief:GetInventory()
    return PLAYER_INVENTORY.inventories[INVENTORY_BACKPACK].slots
end

function BriefThief:Chat(msg)
    d(self.colors[self.curColor]..msg)
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
	local plural,sclem,timer="s",nil,GetTimeToClemencyResetInSeconds() -- timer adds clemency data as total seconds
    if(StolenNumber==1) then plural="" end -- mandatory string ocd
	if(self.clemency and timer ~= 0) then sclem="  -  "..(math.floor(timer/3600)).."h "..(math.ceil(timer%3600/60)).."m clemency cooldown" else sclem="" end -- string clemency
 	if(who=="fence" and fcache==math.ceil(StolenValue*bonus)) then return else self:Chat(tostring(StolenNumber).." stolen item"..plural.." worth "..tostring(math.ceil(StolenValue*bonus)).." gold"..sclem.." |r") end
	if(self.debug) then self:Chat("clemency "..tostring(self.clemency).." - guards "..self.guardString:lower().." / "..tostring(self.showGuard).." - fence "..self.fenceString:lower().." / "..tostring(self.showFence).." - fcache "..tostring(fcache)) end -- prints debug line if enabled
	if(who=="fence") then fcache=math.ceil(StolenValue*bonus) end -- if check came from fence then we save total value to fence cache
end -- mutiny thinks he did the math correctly but he retook algebra twice so who can be sure

-- Settings --
function BriefThief:UpdateClemency(value)
	self.clemency=value
	self.persistentSettings.clemency=self.clemency
	if self.debug then self:Chat("Brief Thief set show clemency to "..tostring(self.clemency)) end
end

function BriefThief:SaveSettings(what,who)
	if who=="guard" then
		self.guardString=what
		self.persistentSettings.gstring=self.guardString
		if self.guardString=="when stopped" then self.showGuard=true
		else self.showGuard=false end
		self.persistentSettings.guard=self.showGuard
		if self.debug then self:Chat("Brief Thief set show "..who.." to "..tostring(self.showGuard)) end
	elseif who=="fence" then
		self.fenceString=what
		self.persistentSettings.fstring=self.fenceString
		if self.fenceString=="when selling" then self.showFence=true
		else self.showFence=false end
		self.persistentSettings.fence=self.showFence
		if self.debug then self:Chat("Brief Thief set show "..who.." to "..tostring(self.showFence)) end
	end
end

function BriefThief:CreateSettings()
    local LAM=LibStub("LibAddonMenu-2.0")
    local defaultSettings={}
    local panelData = {
	    type = "panel",
	    name = "Brief Thief",
	    displayName = "|cffa700Brief|r Thief",
	    author = "mutiny and Jackarunda :^)",
        version = tostring(self.ver),
		registerForDefaults = true,
        slashCommand = "/briefthief"
    }
    local optionsData = {
        [1] = {
            type = "header", -- DISPLAY SETTINGS
            name = "|cffa700Display|r settings",
            width = "full",
            },
         [2] = {
            type = "checkbox", 
            name = " Show clemency skill cooldown",
			warning = "Requires clemency skill to do anything",
            width = "half",
            getFunc = function() return self.clemency end,
            setFunc = function(value) self:UpdateClemency(value) end,
            },
         [3] = {
            type = "dropdown",
            name = "Message color",
            choices = {"red","green","blue","cyan","magenta","yellow","orange","purple","pink","brown","white","black","gray"},
            width = "half",
            getFunc = function() return self.curColor end,
            setFunc = function(value) end,
            },
         [4] = {
            type = "header", -- START THIEF SETTINGS --
            name = "|cffa700Thief|r settings",
            width = "full",
            },
        [5] = {
            type = "description",
            text = " Adjust when Brief Thief shows information. Save keybind in control settings.",
            width = "full",           
            },
        [6] = {
            type = "divider",
            width = "full",           
            },
         [7] = {
            type = "dropdown",
            name = " Show on guards",
            choices = {"when stopped","never"},
            width = "half",
            getFunc = function() return self.guardString end,
            setFunc = function(value) brtf:SaveSettings(value,"guard") end,
            },
         [8] = {
            type = "dropdown",
            name = " Show on fences",
            choices = {"when selling","never"},
            width = "half",
            getFunc = function() return self.fenceString end,
            setFunc = function(value) brtf:SaveSettings(value,"fence") end,
            },
         [9] = {
            type = "submenu", -- START ABOUT MESSAGE --
            name = "|cffa700About|r message",
            width = "full",
			controls= {
				[1] = {
					type = "description",
					text = " More features are planned, just have to find time to impliment them.",
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
SLASH_COMMANDS["/loot"]=function(cmd)
    if(cmd=="guard" or cmd=="fence") then brtf:ToggleEvent(cmd)
    elseif (cmd=="clem" or cmd=="clemency") then brtf:ToggleEvent(cmd)
    elseif (cmd=="help") then brtf:Help()
	elseif (cmd=="DEBUG") then -- for when mutiny breaks something
		local sdebug=nil if brtf.debug then sdebug="|cff0000 disabled" else sdebug="|c00ff00 enabled" end
		d(brtf.colors[brtf.curColor].."Brief Thief|r"..brtf.colors.yellow.." debug mode|r"..sdebug.."|r")
		brtf.debug=not brtf.debug
		brtf.persistentSettings.debug=brtf.debug
    elseif (cmd and cmd~="") then brtf:ChangeColor(cmd)
    else brtf:Check() end
end

SLASH_COMMANDS["//"]=function() if brtf.debug then ReloadUI() end end

EVENT_MANAGER:RegisterForEvent("BriefThief_OnLoaded",EVENT_ADD_ON_LOADED,function() BriefThief:Initialize() end)