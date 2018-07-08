BriefThief = {

	ver = 3.2,
	color = {},		-- message color
	guard = nil, 	-- show on guard
	fence = nil, 	-- show on fence
	theft = nil,	-- show on theft
	clemency = nil, -- show clemency

	persistentSettings = {},

	defaultPersistentSettings = {
		color = { 1, .65, 0 },
		-- color is rgb format
		guard = true,
		fence = true,
		theft = true,
		clemency = true,
	}
}

--[[ initialize ]]--
local bt = BriefThief

function bt:Initialize()
	bt.persistentSettings = ZO_SavedVars:NewAccountWide("BriefThiefVars", 3.1, nil, bt.defaultPersistentSettings)
	ZO_CreateStringId("SI_BINDING_NAME_DEBRIEF", "Debrief")
	EVENT_MANAGER:UnregisterForEvent("BriefThief_OnLoaded",EVENT_ADD_ON_LOADED)
	RestorePreferences() -- apply persistent settings to addon
	ApplyUpdatePatches() -- uh oh mutiny changed internal data
	CreateSettings() -- builds addons setting screen with LAM2
end

-- assign persistent settings
function RestorePreferences()
	bt.color = bt.persistentSettings.color
	bt.guard = bt.persistentSettings.guard
	bt.fence = bt.persistentSettings.fence
	bt.theft = bt.persistentSettings.theft
	bt.clemency = bt.persistentSettings.clemency
end

-- fixes persistent settings
function ApplyUpdatePatches()
	-- update bt.color datatype in 3.2+ 
	if (type(bt.color) ~= "table") then
		bt.color = bt.defaultPersistentSettings.color
		bt.persistentSettings.color = bt.color
	end
end


--[[ convienence methods ]]--

-- colors chat message
function Chat(message)
    d(getColorHex() .. message)
end

-- get clemency countdown
function GetClemencyInfo()
	local timer = GetTimeToClemencyResetInSeconds()
	local countdown = " - clemency in ".. (math.floor(timer/3600)) .. "h " .. (math.ceil(timer%3600/60)) .. "m"
	return timer, countdown
end

-- get stolen items data 
function GetStolenItems()
	local bonus = ZO_Fence_Manager:GetHagglingBonus()
	local totalStolen = 0
	local totalValues = 0

	-- get relevant info about stolen items
	local bagCount = GetBagSize(BAG_BACKPACK) 
	local slotId for slotId = 0, bagCount, 1 do 
		if IsItemStolen(BAG_BACKPACK, slotId) then 
			local icon, stack, sellPrice = GetItemInfo(BAG_BACKPACK, slotId)
			-- math that calculates percentage increase with haggle skill bonus (if bonus is not nil)
			local value = bonus > 0 and math.ceil(((bonus/100) * sellPrice) + sellPrice) or sellPrice

			totalStolen = totalStolen + stack
			totalValues = totalValues + (value * stack)			
		end
	end

	return totalStolen, totalValues
end


--[[ brief thief methods ]]--

-- send to chatbox
function Debrief()
	local stolen, value = GetStolenItems()
	local timer, countdown = GetClemencyInfo()
	if (not bt.clemency or timer == 0) then countdown = "" end
	Chat(stolen .. " stolen items worth " .. value .. " gold" .. countdown)
end

-- handle /loot command calls
function HandleCommand(extra)
	-- figure out wtf the commands doing
	if (extra == "debug") then Debug(bt)
	elseif (extra == "guard") then UpdateGuardPref()
	elseif (extra == "fence") then UpdateFencePref()
	elseif (extra == "steal") then UpdateTheftPref()
	else Debrief() end
end

-- calls when keybind pressed
function BriefThief_Keybind()
	Debrief()
end

-- get recursive data
function Debug(table)
	-- post all internal variables
	for key, value in pairs(table) do
		if (type(value) ~= "function") then
			if (type(value) ~= "table") then
				-- todo: somehow display key hiarchy
				Chat(key .. " : " .. tostring(value))
			else Debug(value) end
		end
	end
end


--[[ settings methods ]]--

-- set text display color
function setColor(r, g, b)
	bt.color = { r, g, b }
	bt.persistentSettings.color = bt.color
end

-- convert rgbs to hex
function getColorHex()
	local hexadecimal = ""
	-- I understand some of this
	for k, v in pairs(bt.color) do
		local hex, value = "", v * 255
		while (value > 0) do
			local index = math.fmod(value, 16) + 1
			value = math.floor(value / 16)
			hex = string.sub('0123456789ABCDEF', index, index) .. hex			
			-- magic internet bullshittery fueled by hopes and dreams
		end

		if (string.len(hex) == 0) then hex = "00"
		elseif (string.len(hex) == 1) then hex = "0" .. hex	end
		hexadecimal = hexadecimal .. hex
	end

	return "|c" .. hexadecimal
end

-- change persistent setting
function UpdateGuardPref(bool)
	if (bool == nil) then 
		bt.guard = not bt.guard -- no value, flip boolean
		Chat("Brief Thief will " .. (bt.guard and "" or "not ") .. "show when talking to guards")
	else bt.guard = bool end -- value passed, set boolean

	bt.persistentSettings.guard = bt.guard
end

-- (see above notes)
function UpdateFencePref(bool)
	if (bool == nil) then
		bt.fence = not bt.fence
		Chat("Brief Thief will " .. (bt.fence and "" or "not ") .. "show when selling to fences")
	else bt.fence = bool end	

	bt.persistentSettings.fence = bt.fence
end

function UpdateTheftPref(bool)
	if (bool == nil) then 
		bt.theft = not bt.theft
		Chat("Brief Thief will " .. (bt.theft and "" or "not ") .. "show when stealing items")
	else bt.theft = bool end	

	bt.persistentSettings.theft = bt.theft
end

function UpdateClemencyPref(bool)
	if (bool == nil) then
		bt.clemency = not bt.clemency 
		Chat("Brief Thief will " .. (bt.clemency and "" or "not ") .. "show the clemency timer")
	else bt.clemency = bool end

	bt.persistentSettings.clemency = bt.clemency
end

-- LAM preferences screen
function CreateSettings()
    local LAM = LibStub("LibAddonMenu-2.0")
    local defaultSettings = {}
    local panelData = {
	    type = "panel",
	    name = "Brief Thief",
	    displayName = getColorHex().."Brief Thief",
	    author = "mutiny",
        version = tostring(bt.ver),
		registerForDefaults = true,
    	registerForRefresh = true,
        slashCommand = "/briefthief"
    }
    local optionsData = {
        [1] = {
            type = "header",
            name = getColorHex().."Display|r settings",
            width = "full",
			},
		[2] = {
			type = "colorpicker",
			name = " Chatbox message color",
			getFunc = function() return bt.color[1], bt.color[2], bt.color[3] end,
			setFunc = function(r, g, b) setColor(r, g, b) end,
			default = { -- why tf does LAM change this format
				r = bt.defaultPersistentSettings.color[1], 
				g = bt.defaultPersistentSettings.color[2], 
				b = bt.defaultPersistentSettings.color[3]}
			},
        [3] = {
            type = "checkbox", 
            name = " Include clemency timer",
            getFunc = function() return bt.clemency end,
			setFunc = function(value) UpdateClemencyPref(value) end,
			default = bt.defaultPersistentSettings.clemency, 
            },
        [4] = {
            type = "header",
            name = getColorHex().."Debrief|r settings",
            width = "full",
            },
		[5] = {
            type = "description",
            text = " Change when to show Brief Thief. You can also use /loot or a game keybind.",
            width = "full",           
            },
        [6] = {
            type = "divider",
            width = "full",           
			},
		[7] = {
			type = "checkbox",
			name = " Show when stealing items",
			getFunc = function() return bt.theft end,
			setFunc = function(bool) UpdateTheftPref(bool) end,
			default = bt.defaultPersistentSettings.theft,
			},
         [8] = {
            type = "checkbox",
            name = " Show when talking to guards",
            getFunc = function() return bt.guard end,
            setFunc = function(bool) UpdateGuardPref(bool) end,
			default = bt.defaultPersistentSettings.guard,
            },
         [9] = {
            type = "checkbox",
            name = " Show when selling to fences",
            getFunc = function() return bt.fence end,
            setFunc = function(bool) UpdateFencePref(bool) end,
			default = bt.defaultPersistentSettings.fence,
            },
         [10] = {
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
					text = " Thank you for understanding and using Brief Thief version "..tostring(bt.ver)..". ツ",
					width = "full",           
            	}
			}
		} 
	}
    LAM:RegisterOptionControls("BriefThief", optionsData)
	LAM:RegisterAddonPanel("BriefThief", panelData)
end


--[[ game hooks ]]--

SLASH_COMMANDS["/loot"] = function(extra) HandleCommand(extra, "loot") end
-- extra is any string input past command, eg /loot debug (extra == debug)

EVENT_MANAGER:RegisterForEvent("BriefThief_OnSteal", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, function(e, bagId, slotId) if (bt.theft and IsItemStolen(bagId, slotId)) then Debrief() end end)
EVENT_MANAGER:RegisterForEvent("BriefThief_OnGuard",EVENT_JUSTICE_BEING_ARRESTED,function() if (bt.guard) then Debrief() end end)
EVENT_MANAGER:RegisterForEvent("BriefThief_OnFence",EVENT_OPEN_FENCE,function() if (bt.fence) then Debrief() end end)
EVENT_MANAGER:RegisterForEvent("BriefThief_OnLoaded",EVENT_ADD_ON_LOADED,function() bt:Initialize() end)