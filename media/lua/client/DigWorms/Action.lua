require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
require "Farming/ISUI/ISFarmingMenu"



--- Setting up worm digging actions ---

local DigWormsAction = ISBaseTimedAction:derive("DigWormsAction")


function DigWormsAction:isValid()
    return true
end


function DigWormsAction:waitToStart()
    self.character:faceLocation(self.gridSquare:getX(), self.gridSquare:getY())
    return self.character:shouldBeTurning()
end


function DigWormsAction:update()
    self.character:faceLocation(self.gridSquare:getX(), self.gridSquare:getY())
    if self.item then
        self.item:setJobDelta(self:getJobDelta())
    end
    self.character:setMetabolicTarget(Metabolics.DiggingSpade)
end


function DigWormsAction:start()
    if self.item then
        self.item:setJobType(getText("ContextMenu_Dig"))
        self.item:setJobDelta(0.0)
        if string.contains(self.item:getType(), "Trowel") then
            self.sound = self.character:playSound("DigFurrowWithTrowel")
        else
            self.sound = self.character:playSound("DigFurrowWithShovel")
        end
    end

    addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), 10, 1)
    self:setActionAnim(ISFarmingMenu.getShovelAnim(self.item))
    if self.item then
        self:setOverrideHandModels(self.item:getStaticModel(), nil)
    end
end


function DigWormsAction:stop()
    if self.sound and self.sound ~= 0 then
        self.character:getEmitter():stopOrTriggerSound(self.sound)
    end
    ISBaseTimedAction.stop(self)
    if self.item then
        self.item:setJobDelta(0.0)
    end
end


function DigWormsAction:perform()

    if self.item then
        self.item:getContainer():setDrawDirty(true)
        self.item:setJobDelta(0.0)
    end
    if self.sound and self.sound ~= 0 then
        self.character:getEmitter():stopOrTriggerSound(self.sound)
    end

    CFarmingSystem.instance:changePlayer(self.character)
    
    -- maybe give worm ?

    local rainIntensity = getClimateManager():getRainIntensity()
    local minRainIntensity = 0.15
    local randRange = 5
    if rainIntensity > minRainIntensity then randRange = 4 end

    if ZombRand(randRange) == 0 then
        self.character:getInventory():AddItem("Base.Worm")
    end
    ISBaseTimedAction.perform(self)

    local sq = self.gridSquare
    local plowAction = DigWormsAction:new(self.character, sq, self.item, 150)
    ISTimedActionQueue.add(plowAction)

end


function DigWormsAction:new(character, square, item, time)

    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = time
    if character:isTimedActionInstant() then
        o.maxTime = 1
    end
    o.item = item
    o.gridSquare = square
    o.caloriesModifier = 5
    return o
end


return DigWormsAction
