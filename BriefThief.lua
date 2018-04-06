BriefThief = {

	ver = 3.0,
	color = "", 	-- message color
	slash = "", 	-- slash command
	guard = nil, 	-- show on guard
	fence = nil, 	-- show on fence
	clemency = nil, -- show clemency
	guardString = "", 	-- option string
	fenceString = "", 	-- option string

	defaultPersistentSettings ={
		color = "orange",
		slash = "/loot",
		guard = true,
		fence = true,
		clemency = true,
		guardString = "when arrested",
		fenceString = "when selling",
	},

	persistentSettings = {},

    colors = {
		red="|cff0000",
		green="|c00ff00",
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

local bt = BriefThief


-- initialize --

function bt:Initialize()
	bt.persistentSettings=ZO_SavedVars:NewAccountWide("BriefThiefVars",self.ver,nil,self.defaultPersistentSettings) -- load in the persistent settings
    ZO_CreateStringId("SI_BINDING_NAME_GetStolenItems_LOOT","GetStolenItems Loot")
	EVENT_MANAGER:UnregisterForEvent("BriefThief_OnLoaded",EVENT_ADD_ON_LOADED)
	bt:RestorePreferences() -- apply persistent settings to addon
	bt:CreateSettings() -- builds addons setting screen with LAM2
end

function bt:RestorePreferences()
	bt.color = bt.persistentSettings.color
	bt.slash = bt.persistentSettings.slash
	bt.guard = bt.persistentSettings.guard
	bt.fence = bt.persistentSettings.fence
	bt.clemency = bt.persistentSettings.clemency
	bt.guardString = bt.persistentSettings.guardString
	bt.fenceString = bt.persistentSettings.fenceString
end


-- convienence --

-- send colored msg
function bt:Chat(msg)
    d(bt.colors[bt.color]..msg)
end

-- get clemency cooldown info
function bt:GetClemencyInfo()
	local timer = GetTimeToClemencyResetInSeconds()
	local countdown = " -- clemency in "..(math.floor(timer/3600)).."h "..(math.ceil(timer%3600/60)).."m"
	return timer, countdown
end

-- get all stolen items data 
function bt:GetStolenItems()
	local bonus = ZO_Fence_Manager:GetHagglingBonus()
	local totalStolen = 0
	local totalValues = 0

	-- get useful information on stolen items
	local bagCount = GetBagSize(BAG_BACKPACK) 
	local slotId for slotId = 0, bagCount, 1 do 
		if IsItemStolen(BAG_BACKPACK, slotId) then 
			local icon, stack, sellPrice = GetItemInfo(BAG_BACKPACK, slotId)
			local value = bonus > 0 and math.ceil(((bonus/100) * sellPrice) + sellPrice) or sellPrice
			-- math that calculates percentage increase from haggle bonus applied per stolen item

			totalStolen = totalStolen + stack
			totalValues = totalValues + (value * stack)			
		end
	end

	return totalStolen, totalValues
end


-- addon methods --

function bt:SendLoot()
	local stolen, value = bt:GetStolenItems()
	local timer, countdown = bt:GetClemencyInfo()
	if (not bt.clemency or timer == 0) then countdown = "" end
	bt:Chat(stolen .. " stolen items worth " .. value .. " gold" .. countdown)
end

-- required for settings control keybind
function BriefThief_GetStolenItemsLoot()
	bt:SendLoot() -- call at key onpress
end

-- handles calling /loot or /thief commands
function bt:PersistentCommand(input, slash)
	-- checks if slash command is user preferenced slash command
    if (slash == "loot" and self.slash ~= "/loot") then return end
    if (slash == "thief" and self.slash ~= "/thief") then return end
	
	-- figure out what the command is supposed to do
	if (input == "guard") then bt:UpdateGuardPref()
	elseif (input == "fence") then bt:UpdateFencePref()
	elseif (input == "clem" or input == "clemency") then bt:UpdateClemencyPref()
	elseif (bt.colors[input]) then bt:ChangeColor(input, "chat")
	else bt:SendLoot() end
end

-- supresses auto guard or fence by prefs
function BriefThief:PersistantHooks(event)
    if ((event == "guard") and (bt.guard)) then bt:SendLoot()
    elseif ((event == "fence") and (bt.fence)) then bt:SendLoot() end
end


-- settings --

-- update display color preference
function bt:ChangeColor(input, from)
	local color = input:lower()
	
	-- check for any errors before we explode
	if (not(bt.colors[color])) then return end
	if (color == bt.color) then return end

	bt.color = color
	bt.persistentSettings.color = bt.color
	if (from == "chat") then bt:Chat("Brief Thief changed color to " ..bt.color) end
end

-- update pref with value or toggle
function bt:UpdateGuardPref(value)
	if (value ~= nil) then
		bt.guardString = value
		bt.guard = value ~= "disabled"
	else -- no value, flip bool
		bt.guard = not bt.guard
		bt.guardString = bt.guard and "when arrested" or "disabled"
		bt:Chat("Brief Thief will " .. (bt.guard and "" or "not ") .. "show when talking to guards")
	end	

	bt.persistentSettings.guard = bt.guard
	bt.persistentSettings.guardString = bt.guardString
end

function bt:UpdateFencePref(value)
	if (value ~= nil) then
		bt.fenceString = value
		bt.fence = value ~= "disabled"
	else
		bt.fence = not bt.fence
		bt.fenceString = bt.fence and "when selling" or "disabled"
		bt:Chat("Brief Thief will " .. (bt.fence and "" or "not ") .. "show when talking to fences")
	end	

	bt.persistentSettings.fence = bt.fence
	bt.persistentSettings.fenceString = bt.fenceString
end

function bt:UpdateClemencyPref(value)
	if (value ~= nil) then bt.clemency = value
	else 
		bt.clemency = not bt.clemency 
		bt:Chat("Brief Thief will " .. (bt.clemency and "" or "not ") .. "show the clemency timer")
	end	    

	bt.persistentSettings.clemency = bt.clemency
end

-- update command preference
function bt:SetCommand(value)
    bt.slash = value
    bt.persistentSettings.slash = value
end

-- LAM2 builds addons setting screen
function BriefThief:CreateSettings()
    local LAM=LibStub("LibAddonMenu-2.0")
    local defaultSettings={}
    local panelData = {
	    type = "panel",
	    name = "Brief Thief",
	    displayName = self.colors[self.color].."Brief Thief",
	    author = "mutiny",
        version = tostring(self.ver),
		registerForDefaults = true,
    	registerForRefresh = true,
        slashCommand = "/briefthief"
    }
    local optionsData = {
        [1] = {
            type = "header",
            name = bt.colors[bt.color].."Display|r settings",
            width = "full",
            },
         [2] = {
            type = "checkbox", 
            name = " Show clemency cooldown",
            width = "half",
            getFunc = function() return bt.clemency end,
            setFunc = function(value) bt:UpdateClemencyPref(value) end,
            },
         [3] = {
            type = "dropdown",
            name = " Message color",
            choices = {"red","green","blue","cyan","magenta","yellow","orange","purple","pink","brown","white","gray"},
            width = "half",
            getFunc = function() return self.color end,
            setFunc = function(value) bt:ChangeColor(value) end,
            },
         [4] = {
            type = "header",
            name = bt.colors[bt.color].."Thief|r settings",
            width = "full",
            },
        [5] = {
            type = "dropdown",
            name = " Slash command",
			choices = {"/loot","/thief"},
			warning ="Using chat commands to modify |cffdb00any|r options without using this settings panel will require ReloadUI to update the changed values here",
			width = "full",
            getFunc = function() return bt.slash end,
            setFunc = function(value) bt:SetCommand(value) end,
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
            getFunc = function() return bt.guardString end,
            setFunc = function(value) bt:UpdateGuardPref(value) end,
            },
         [10] = {
            type = "dropdown",
            name = " Show on fences",
            choices = {"when selling","disabled"},
            width = "full",
            getFunc = function() return bt.fenceString end,
            setFunc = function(value) bt:UpdateFencePref(value) end,
            },
         [11] = {
            type = "submenu",
            name = "About message",
            width = "full",
			controls= {
				[1] = {
					type = "description",
					text = " Please send me any bugs or feature requests. I am always listening for them!",
					width = "full",           
					},
				[2] = {
					type = "description",
					text = " I am a hobby dev learning lower level programming so I may be slow replying.",
					width = "full",           
					},
				[3] = {
					type = "description",
					text = " Source is available online at GitHub: |cffdb00https://github.com/notmutiny/Brief-Thief|r",
					width = "full",           
					},
				[4] = {
					type = "description",
					text = " Thank you for understanding and using Brief Thief version "..tostring(self.ver)..". ツ",
					width = "full",           
            	}
			}
		} 
	}
    LAM:RegisterOptionControls("BriefThief", optionsData)
	LAM:RegisterAddonPanel("BriefThief", panelData)
end

-- game hooks --

SLASH_COMMANDS["/loot"] = function(cmd) bt:PersistentCommand(cmd, "loot") end
SLASH_COMMANDS["/thief"] = function(cmd) bt:PersistentCommand(cmd, "thief") end
-- cmd in function(cmd) is any input past command, eg /loot guard (cmd == guard)

EVENT_MANAGER:RegisterForEvent("BriefThief_OpenFence",EVENT_OPEN_FENCE,function() bt:PersistantHooks("fence") end)
EVENT_MANAGER:RegisterForEvent("BriefThief_ArrestGetStolenItems",EVENT_JUSTICE_BEING_ARRESTED,function() bt:PersistantHooks("guard") end)
EVENT_MANAGER:RegisterForEvent("BriefThief_OnLoaded",EVENT_ADD_ON_LOADED,function() BriefThief:Initialize() end)