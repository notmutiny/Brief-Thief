-- Global table
BriefThief={}

local self=BriefThief

-- Initialize
function BriefThief:Initialize()
    self.savedVariables = ZO_SavedVars:New("BriefThiefVars", self.version, nil, self.Default)
    EVENT_MANAGER:UnregisterForEvent(self.name,EVENT_ADD_ON_LOADED)
end

-- Variables
self.version=1.1
self.color={"|cffa700","orange"}
self.prevColor={}
self.pushChat=0

-- Convienence Functions
local function confirm()
    if self.pushChat==0 then return end
    if self.pushColor==0 then return end
    self.color=self.prevColor
    d(self.color[1].."Color has updated successfully.")
    self.pushChat=0
    self.pushColor=0
end

local function broadcast()
    if self.color[1]==self.prevColor[1] then return end
    d(self.color[1].."Brief Thief has been set to |r"..self.prevColor[1]..""..self.prevColor[2].."|r"..self.color[1].."!")
    d(self.prevColor[1].."Type /lootyes to confirm changes.|r")
    self.pushChat=0
end

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

-- Savings still broke af
local function save()
--	if self.savedVariables.color then
--    self.savedVariables.color = self.color
--    end
--    else return 0 end
end

-- Addon Member Vars
function self:GetInventory()
    return PLAYER_INVENTORY.inventories[INVENTORY_BACKPACK].slots
end

function self:Check()
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
    d(self.color[1]..""..tostring(StolenNumber).." stolen item"..plural.." worth "..tostring(StolenValue).." gold|r")
end  
  
-- Game hooks
SLASH_COMMANDS["/lootyes"]=function() self.pushChat=1 confirm() end
SLASH_COMMANDS["/lootr"]=function() self.pushColor=1 self.prevColor={"|cff0000","red"} broadcast() end
SLASH_COMMANDS["/looto"]=function() self.pushColor=1 self.prevColor={"|cffa700","orange"} broadcast() end
SLASH_COMMANDS["/looty"]=function() self.pushColor=1 self.prevColor={"|cffff00","yellow"} broadcast() end
SLASH_COMMANDS["/loot"]=function() self:Check() end
EVENT_MANAGER:RegisterForEvent("BriefThief_ArrestCheck",EVENT_JUSTICE_BEING_ARRESTED,function() self:Check() end)