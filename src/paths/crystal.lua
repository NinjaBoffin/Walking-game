-- Crystal Gather Path Module
-- Handles gathering crystals and polish/tumble transforms

local Crystal = {}

-- Crystal items
Crystal.ITEMS = {
    CRYSTAL_SHARD = "crystal_shard",
    POLISHED_CRYSTAL = "polished_crystal",
    TUMBLED_STONE = "tumbled_stone"
}

-- Transform recipes
Crystal.TRANSFORMS = {
    POLISH = {
        name = "Polish Crystal",
        input = { {item = Crystal.ITEMS.CRYSTAL_SHARD, quantity = 2} },
        output = { {item = Crystal.ITEMS.POLISHED_CRYSTAL, quantity = 1} },
        stepCost = 150,
        description = "Polish 2 crystal shards into 1 polished crystal"
    },
    TUMBLE = {
        name = "Tumble Stones",
        input = { {item = Crystal.ITEMS.CRYSTAL_SHARD, quantity = 3} },
        output = { {item = Crystal.ITEMS.TUMBLED_STONE, quantity = 1} },
        stepCost = 180,
        description = "Tumble 3 crystal shards into 1 tumbled stone"
    }
}

-- Gather configuration
Crystal.GATHER_CONFIG = {
    stepCost = 120, -- Live steps required (90-140 range)
    output = { {item = Crystal.ITEMS.CRYSTAL_SHARD, quantity = 1} },
    duration = 3.5 -- Seconds for prototype (slightly longer than herbs)
}

-- Check if can perform transform
function Crystal.canTransform(transformType, inventory)
    local transform = Crystal.TRANSFORMS[transformType]
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
function Crystal.performTransform(transformType, inventory, stepSystem)
    local transform = Crystal.TRANSFORMS[transformType]
    if not transform then
        return false, "Invalid transform type"
    end
    
    -- Check requirements
    local canTransform, errorMsg = Crystal.canTransform(transformType, inventory)
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
function Crystal.getGatherAction()
    return {
        name = "Gathering Crystals",
        type = "gather",
        path = "crystal",
        stepCost = Crystal.GATHER_CONFIG.stepCost,
        duration = Crystal.GATHER_CONFIG.duration,
        output = Crystal.GATHER_CONFIG.output
    }
end

return Crystal


