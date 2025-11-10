-- Equipment System Module
-- Manages equipped items and their passive effects

local Equipment = {}

-- Equipment slots
Equipment.SLOTS = {
    PENDANT = "pendant",
    BRACELET = "bracelet",
    WRAP = "wrap"
}

-- Currently equipped items
Equipment.equipped = {
    pendant = nil,
    bracelet = nil,
    wrap = nil
}

-- Active consumables (1 Tea + 1 Potion)
Equipment.activeConsumables = {
    tea = nil,
    potion = nil
}

-- Initialize equipment system
function Equipment.init()
    Equipment.equipped = {
        pendant = nil,
        bracelet = nil,
        wrap = nil
    }
    Equipment.activeConsumables = {
        tea = nil,
        potion = nil
    }
    print("Equipment system initialized")
end

-- Equip an item to a slot
function Equipment.equip(slot, itemId, effect)
    if not Equipment.SLOTS[string.upper(slot)] then
        return false, "Invalid equipment slot"
    end
    
    Equipment.equipped[slot] = {
        itemId = itemId,
        effect = effect
    }
    
    return true, string.format("Equipped %s to %s slot", itemId, slot)
end

-- Unequip an item from a slot
function Equipment.unequip(slot)
    if not Equipment.SLOTS[string.upper(slot)] then
        return false, "Invalid equipment slot"
    end
    
    local item = Equipment.equipped[slot]
    Equipment.equipped[slot] = nil
    
    if item then
        return true, string.format("Unequipped %s", item.itemId)
    else
        return false, "Slot was empty"
    end
end

-- Activate a consumable (Tea or Potion)
function Equipment.activateConsumable(consumableType, itemId, effect)
    if consumableType ~= "tea" and consumableType ~= "potion" then
        return false, "Can only activate tea or potion"
    end
    
    Equipment.activeConsumables[consumableType] = {
        itemId = itemId,
        effect = effect,
        stepsRemaining = effect.duration or 0,
        usesRemaining = effect.uses or 0
    }
    
    return true, string.format("Activated %s", itemId)
end

-- Use a snack (instant effect)
function Equipment.useSnack(effect, stepSystem)
    if effect.type == "instant_refund" then
        stepSystem.addToBank(effect.amount)
        return true, string.format("Refunded %d steps!", effect.amount)
    end
    
    return false, "Unknown snack effect"
end

-- Update consumable durations (call after steps are spent)
function Equipment.updateConsumables(stepsSpent)
    -- Update tea duration
    if Equipment.activeConsumables.tea then
        Equipment.activeConsumables.tea.stepsRemaining = 
            Equipment.activeConsumables.tea.stepsRemaining - stepsSpent
        
        if Equipment.activeConsumables.tea.stepsRemaining <= 0 then
            print(string.format("%s expired", Equipment.activeConsumables.tea.itemId))
            Equipment.activeConsumables.tea = nil
        end
    end
    
    -- Update potion uses (handled separately when crafting)
end

-- Decrement potion uses (call after each craft)
function Equipment.decrementPotionUses()
    if Equipment.activeConsumables.potion then
        Equipment.activeConsumables.potion.usesRemaining = 
            Equipment.activeConsumables.potion.usesRemaining - 1
        
        if Equipment.activeConsumables.potion.usesRemaining <= 0 then
            print(string.format("%s expired", Equipment.activeConsumables.potion.itemId))
            Equipment.activeConsumables.potion = nil
        end
    end
end

-- Calculate total cost reduction for an action
function Equipment.getCostReduction(actionType)
    local totalReduction = 0
    local maxReduction = 0.10 -- 10% cap per GDD
    
    -- Check equipped items
    for slot, item in pairs(Equipment.equipped) do
        if item and item.effect.type == "reduce_cost" then
            if item.effect.target == actionType or item.effect.target == "all" then
                totalReduction = totalReduction + item.effect.amount
            end
        end
    end
    
    -- Check active tea
    if Equipment.activeConsumables.tea then
        local effect = Equipment.activeConsumables.tea.effect
        if effect.type == "reduce_cost" and effect.target == actionType then
            totalReduction = totalReduction + effect.amount
        end
    end
    
    -- Apply cap
    return math.min(totalReduction, maxReduction)
end

-- Check if bonus item should be awarded (for bracelet effects)
function Equipment.checkBonusChance(actionType)
    for slot, item in pairs(Equipment.equipped) do
        if item and item.effect.type == "bonus_chance" then
            if item.effect.target == actionType then
                -- Roll for bonus
                if math.random() < item.effect.chance then
                    return true, item.effect.bonus
                end
            end
        end
    end
    
    return false, 0
end

-- Get all active effects (for display)
function Equipment.getActiveEffects()
    local effects = {}
    
    -- Equipped items
    for slot, item in pairs(Equipment.equipped) do
        if item then
            table.insert(effects, {
                source = slot,
                itemId = item.itemId,
                effect = item.effect
            })
        end
    end
    
    -- Active consumables
    if Equipment.activeConsumables.tea then
        table.insert(effects, {
            source = "tea",
            itemId = Equipment.activeConsumables.tea.itemId,
            effect = Equipment.activeConsumables.tea.effect,
            remaining = Equipment.activeConsumables.tea.stepsRemaining
        })
    end
    
    if Equipment.activeConsumables.potion then
        table.insert(effects, {
            source = "potion",
            itemId = Equipment.activeConsumables.potion.itemId,
            effect = Equipment.activeConsumables.potion.effect,
            remaining = Equipment.activeConsumables.potion.usesRemaining
        })
    end
    
    return effects
end

-- Reset equipment system
function Equipment.reset()
    Equipment.init()
    print("Equipment reset")
end

return Equipment


