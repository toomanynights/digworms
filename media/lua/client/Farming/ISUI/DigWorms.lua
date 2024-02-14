require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
require "Farming/ISUI/ISFarmingMenu"


--- Rewriting shovel functions to add a cursor ---


ISFarmingMenu.onShovel = function(worldobjects, plant, player, sq)

    if not ISFarmingMenu.walkToPlant(player, sq) then
        return;
    end
    local handItem = ISWorldObjectContextMenu.equip(player, player:getPrimaryHandItem(), ISFarmingMenu.getShovel(player), true);
	
	ISTimedActionQueue.add(ISShovelAction:new(player, handItem, plant, 40));
	ISFarmingMenu.cursor = ISFarmingCursorMouse:new(player, ISFarmingMenu.onShovelSelected, ISFarmingMenu.isShovelValid)
	getCell():setDrag(ISFarmingMenu.cursor, player:getPlayerNum())
	
end

ISFarmingMenu.onShovelSelected = function()

	local cursor = ISFarmingMenu.cursor
	local playerObj = cursor.character
	if not ISFarmingMenu.walkToPlant(playerObj, cursor.sq) then
		return
	end
	local plant = CFarmingSystem.instance:getLuaObjectOnSquare(cursor.sq)
	local handItem = playerObj:getPrimaryHandItem() 
	
	ISTimedActionQueue.add(ISShovelAction:new(playerObj, handItem, plant, 40));

end

function ISFarmingMenu:isShovelValid()

	if not ISFarmingMenu.cursor then return false; end
	local valid = true
	local cursor = ISFarmingMenu.cursor
	local playerObj = cursor.character
	local playerInv = playerObj:getInventory()
	local plant = CFarmingSystem.instance:getLuaObjectOnSquare(cursor.sq)
	local plantName = ISFarmingMenu.getPlantName(plant)
	
	if not ISFarmingMenu.isValidPlant(plant) then
		cursor.tooltipTxt = "<RGB:1,0,0> " .. getText("Farming_Tooltip_NotAPlant")
		return false
	end

	cursor.tooltipTxt = plantName .. " <LINE> ";
	cursor.tooltipTxt = cursor.tooltipTxt .. getText('Tooltip_RemoveThisFurrow')

	return true
	
end



--- Setting up worm digging actions ---


digWormsAction = ISBaseTimedAction:derive("digWormsAction");

function digWormsAction:isValid()
	return true;
end

function digWormsAction:waitToStart()
	self.character:faceLocation(self.gridSquare:getX(), self.gridSquare:getY())
	return self.character:shouldBeTurning()
end

function digWormsAction:update()
	self.character:faceLocation(self.gridSquare:getX(), self.gridSquare:getY())
    if self.item then
	    self.item:setJobDelta(self:getJobDelta());
    end
    self.character:setMetabolicTarget(Metabolics.DiggingSpade);
end

function digWormsAction:start()
    if self.item then
        self.item:setJobType(getText("ContextMenu_Dig"));
        self.item:setJobDelta(0.0);
        if string.contains(self.item:getType(), "Trowel") then
            self.sound = self.character:playSound("DigFurrowWithTrowel");
        else
            self.sound = self.character:playSound("DigFurrowWithShovel");
        end
    end
 
    addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), 10, 1)
	self:setActionAnim(ISFarmingMenu.getShovelAnim(self.item))
	if self.item then
		self:setOverrideHandModels(self.item:getStaticModel(), nil)
	end
end

function digWormsAction:stop()
    if self.sound and self.sound ~= 0 then
        self.character:getEmitter():stopOrTriggerSound(self.sound)
    end
    ISBaseTimedAction.stop(self);
    if self.item then
        self.item:setJobDelta(0.0);
    end
end

function digWormsAction:perform()

    if self.item then
        self.item:getContainer():setDrawDirty(true);
        self.item:setJobDelta(0.0);
    end
    if self.sound and self.sound ~= 0 then
        self.character:getEmitter():stopOrTriggerSound(self.sound)
    end

	CFarmingSystem.instance:changePlayer(self.character)
    -- maybe give worm ?
    if ZombRand(5) == 0 then
        self.character:getInventory():AddItem("Base.Worm");
    end
	ISBaseTimedAction.perform(self);
	
	local sq = self.gridSquare
	local plowAction = digWormsAction:new(self.character, sq, self.item, 150)
	ISTimedActionQueue.add(plowAction);
	
end

function digWormsAction:new (character, square, item, time)

	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.maxTime = time;
	if character:isTimedActionInstant() then
		o.maxTime = 1;
	end
	o.item = item;
	o.gridSquare = square
    o.caloriesModifier = 5;
	return o
end




--- Main control of worm digging ---


function walkToWarmDiggingSite(playerObj, square)

	if AdjacentFreeTileFinder.isTileOrAdjacent(playerObj:getCurrentSquare(), square) then
		return true
	end
	local adjacent = AdjacentFreeTileFinder.Find(square, playerObj)
	if adjacent == nil then return false end
	ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, adjacent))
	return true
	
end

function digWorms(worldobjects, player, handItem, sq)

	if handItem then
		ISInventoryPaneContextMenu.equipWeapon(handItem, true, handItem:isTwoHandWeapon(), player:getPlayerNum())
	end
	
	walkToWarmDiggingSite(player, sq)
	local plowAction = digWormsAction:new(player, sq, handItem, 150)
	ISTimedActionQueue.add(plowAction);
	
end


function digWormsContext(playerIndex, context, worldobjects, test) 

	local digOption = context:getOptionFromName(getText("ContextMenu_Dig"));
	local player = getSpecificPlayer(playerIndex)
	local shovel = ISFarmingMenu.getShovel(player)
	local sq = worldobjects[1]:getSquare();

	if digOption then
		context:insertOptionAfter(getText("ContextMenu_Dig"), getText("ContextMenu_DigWormsAction"), worldobjects, digWorms, player, shovel, sq);	
	end

end

Events.OnFillWorldObjectContextMenu.Add(digWormsContext);


