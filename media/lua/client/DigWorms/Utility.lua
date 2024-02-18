require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
require "Farming/ISUI/ISFarmingMenu"

local DigWormsAction = require("DigWorms/Action")

local DigWorms = {}


--- Main control of worm digging ---

DigWorms.walkToWormDiggingSite = function(player, square)

    if AdjacentFreeTileFinder.isTileOrAdjacent(player:getCurrentSquare(), square) then
        return true
    end
    local adjacent = AdjacentFreeTileFinder.Find(square, player)
    if adjacent == nil then
        return false
    end
    ISTimedActionQueue.add(ISWalkToTimedAction:new(player, adjacent))
    return true

end


DigWorms.beginDigging = function(player, handItem, sq)

    if handItem then
        ISInventoryPaneContextMenu.equipWeapon(handItem, true, handItem:isTwoHandWeapon(), player:getPlayerNum())
    end

    DigWorms.walkToWormDiggingSite(player, sq)
    local plowAction = DigWormsAction:new(player, sq, handItem, 150)
    ISTimedActionQueue.add(plowAction)

end


DigWorms.addToContext = function(playerIndex, context, worldObjects, test)

    local digOption = context:getOptionFromName(getText("ContextMenu_Dig"))

    if not digOption then return end
    if #worldObjects == 0 then return end

    local player = getSpecificPlayer(playerIndex)
    local shovel = ISFarmingMenu.getShovel(player)
    local sq = worldObjects[1]:getSquare()

    context:insertOptionAfter(getText("ContextMenu_Dig"), getText("ContextMenu_DigWormsAction"), 
    player, DigWorms.beginDigging, shovel, sq)

end


Events.OnFillWorldObjectContextMenu.Add(DigWorms.addToContext)
return DigWorms
