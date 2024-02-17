require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
require "Farming/ISUI/ISFarmingMenu"

local DigWorms = {}
local DigWormsAction = require("DigWorms/Action")

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


DigWorms.beginDigging = function(worldobjects, player, handItem, sq)

    if handItem then
        ISInventoryPaneContextMenu.equipWeapon(handItem, true, handItem:isTwoHandWeapon(), player:getPlayerNum())
    end

    DigWorms.walkToWormDiggingSite(player, sq)
    local plowAction = DigWormsAction:new(player, sq, handItem, 150)
    ISTimedActionQueue.add(plowAction)

end


DigWorms.addToContext = function(playerIndex, context, worldobjects, test)

    local digOption = context:getOptionFromName(getText("ContextMenu_Dig"))
    local player = getSpecificPlayer(playerIndex)
    local shovel = ISFarmingMenu.getShovel(player)
    local sq = worldobjects[1]:getSquare()

    if digOption then
        context:insertOptionAfter(getText("ContextMenu_Dig"), getText("ContextMenu_DigWormsAction"), worldobjects,
            DigWorms.beginDigging, player, shovel, sq)
    end

end


Events.OnFillWorldObjectContextMenu.Add(DigWorms.addToContext)
return DigWorms