-- Shores Gather Path Module
-- Handles gathering shore materials and salt/press transforms

local Shores = {}

-- Shore items
Shores.ITEMS = {
    SHELL = "shell",
    SEA_SALT = "sea_salt",
    KELP_FLAKES = "kelp_flakes"
}

-- Transform recipes
Shores.TRANSFORMS = {
    SALT = {
        name = "Extract Sea Salt",
        input = { {item = Shores.ITEMS.SHELL, quantity = 2} },
        output = { {item = Shores.ITEMS.SEA_SALT, quantity = 1} },
        stepCost = 140,
        description = "Extract sea salt from 2 shells"
    },
    PRESS = {
        name = "Press Kelp",
        input = { {item = Shores.ITEMS.SHELL, quantity = 3} },
        output = { {item = Shores.ITEMS.KELP_FLAKES, quantity = 1} },
        stepCost = 160,
        description = "Press 3 shells into kelp flakes"
    }
}

-- Gather configuration
Shores.GATHER_CONFIG = {
    stepCost = 110, -- Live steps required (90-140 range)
    output = { {item = Shores.ITEMS.SHELL, quantity = 1} },
    duration = 3.2 -- Seconds for prototype
}

-- Check if can perform transform
function Shores.canTransform(transformType, inventory)
    local transform = Shores.TRANSFORMS[transformType]
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
function Shores.performTransform(transformType, inventory, stepSystem)
    local transform = Shores.TRANSFORMS[transformType]
    if not transform then
        return false, "Invalid transform type"
    end
    
    -- Check requirements
    local canTransform, errorMsg = Shores.canTransform(transformType, inventory)
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
function Shores.getGatherAction()
    return {
        name = "Gathering Shells",
        type = "gather",
        path = "shores",
        stepCost = Shores.GATHER_CONFIG.stepCost,
        duration = Shores.GATHER_CONFIG.duration,
        output = Shores.GATHER_CONFIG.output
    }
end

return Shores


