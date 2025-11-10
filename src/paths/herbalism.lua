-- Herbalism Gather Path Module
-- Handles gathering herbs and press/dry transforms

local Herbalism = {}

-- Herbalism items
Herbalism.ITEMS = {
    HERB = "herb",
    DRIED_HERB = "dried_herb",
    PRESSED_FLOWER = "pressed_flower"
}

-- Transform recipes
Herbalism.TRANSFORMS = {
    DRY = {
        name = "Dry Herbs",
        input = { {item = Herbalism.ITEMS.HERB, quantity = 2} },
        output = { {item = Herbalism.ITEMS.DRIED_HERB, quantity = 1} },
        stepCost = 120,
        description = "Dry 2 herbs into 1 dried herb"
    },
    PRESS = {
        name = "Press Flowers",
        input = { {item = Herbalism.ITEMS.HERB, quantity = 3} },
        output = { {item = Herbalism.ITEMS.PRESSED_FLOWER, quantity = 1} },
        stepCost = 150,
        description = "Press 3 herbs into 1 pressed flower"
    }
}

-- Gather configuration
Herbalism.GATHER_CONFIG = {
    stepCost = 100, -- Live steps required (90-140 range)
    output = { {item = Herbalism.ITEMS.HERB, quantity = 1} },
    duration = 3.0 -- Seconds for prototype
}

-- Check if can perform transform
function Herbalism.canTransform(transformType, inventory)
    local transform = Herbalism.TRANSFORMS[transformType]
    if not transform then
        return false, "Invalid transform type"
    end
    
    -- Check inputs
    for _, input in ipairs(transform.input) do
        local count = inventory.getItemCount(input.item)
        if count < input.quantity then
            return false, string.format("Need %d %s, have %d", input.quantity, input.item, count)
        end
    end
    
    return true, nil
end

-- Perform transform (without spending steps - steps already spent)
function Herbalism.performTransform(transformType, inventory, stepSystem)
    local transform = Herbalism.TRANSFORMS[transformType]
    if not transform then
        return false, "Invalid transform type"
    end
    
    -- Check requirements
    local canTransform, errorMsg = Herbalism.canTransform(transformType, inventory)
    if not canTransform then
        return false, errorMsg
    end
    
    -- Note: Steps are spent by ActionRunner before this is called
    
    -- Remove inputs
    for _, input in ipairs(transform.input) do
        inventory.removeItem(input.item, input.quantity)
    end
    
    -- Add outputs
    for _, output in ipairs(transform.output) do
        inventory.addItem(output.item, output.quantity)
    end
    
    return true, transform.description
end

-- Get gather action data
function Herbalism.getGatherAction()
    return {
        name = "Gathering Herbs",
        type = "gather",
        path = "herbalism",
        stepCost = Herbalism.GATHER_CONFIG.stepCost,
        duration = Herbalism.GATHER_CONFIG.duration,
        output = Herbalism.GATHER_CONFIG.output
    }
end

return Herbalism

