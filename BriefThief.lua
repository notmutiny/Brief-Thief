-- Global Addon Declaration --
BriefThief=BriefThief or {}
 
-- Convenience Functions --
local function TableLength(tab)
    if not(tab)then return 0 end
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
 
-- Addon Member Vars --
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
    local Plural="s"
    if(StolenNumber==1)then Plural="" end
    d("|cff0000"..tostring(StolenNumber).." stolen item"..Plural.." worth "..tostring(StolenValue).." gold|r")
end
 
-- ESO Game Hooks --
SLASH_COMMANDS["/loot"]=function() BriefThief:Check() end
EVENT_MANAGER:RegisterForEvent("BriefThief_ArrestCheck",EVENT_JUSTICE_BEING_ARRESTED,function() BriefThief:Check() end)
 
-- Snippets for Reference --
-- printing in red d(Eventually this table will contain code to show total |cff0000stolen|r loot")