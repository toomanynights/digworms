require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
require "Farming/ISUI/ISFarmingMenu"

--- Rewriting shovel functions to add a cursor ---

local DigWormsDecorations = {}
DigWormsDecorations.FarmingMenu = {}
DigWormsDecorations.FarmingMenu.onShovel = ISFarmingMenu.onShovel

ISFarmingMenu.onShovel = function(worldObjects, plant, player, sq)

    DigWormsDecorations.FarmingMenu.onShovel(worldObjects, plant, player, sq)
    
    ISFarmingMenu.cursor = ISFarmingCursorMouse:new(player, 
        ISFarmingMenu.onShovelSelected, ISFarmingMenu.isShovelValid)
    getCell():setDrag(ISFarmingMenu.cursor, player:getPlayerNum())

end


ISFarmingMenu.onShovelSelected = function()

    local cursor = ISFarmingMenu.cursor
    local player = cursor.character
    if not ISFarmingMenu.walkToPlant(player, cursor.sq) then
        return
    end
    local plant = CFarmingSystem.instance:getLuaObjectOnSquare(cursor.sq)
    local handItem = player:getPrimaryHandItem()

    ISTimedActionQueue.add(ISShovelAction:new(player, handItem, plant, 40))

end


ISFarmingMenu.isShovelValid = function()

    if not ISFarmingMenu.cursor then
        return false
    end
    local valid = true
    local cursor = ISFarmingMenu.cursor
    local player = cursor.character
    local playerInv = player:getInventory()
    local plant = CFarmingSystem.instance:getLuaObjectOnSquare(cursor.sq)
    local plantName = ISFarmingMenu.getPlantName(plant)

    if not ISFarmingMenu.isValidPlant(plant) then
        cursor.tooltipTxt = "<RGB:1,0,0> " .. getText("Farming_Tooltip_NotAPlant")
        return false
    end

    cursor.tooltipTxt = plantName .. " <LINE> "
    cursor.tooltipTxt = cursor.tooltipTxt .. getText('Tooltip_RemoveThisFurrow')

    return true

end

return DigWormsDecorations
