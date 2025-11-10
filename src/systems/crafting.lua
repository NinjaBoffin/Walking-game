-- Crafting System Module
-- Handles consumables and equipment crafting

local Crafting = {}

-- Consumable types
Crafting.CONSUMABLE_TYPES = {
    TEA = "tea",
    POTION = "potion",
    SNACK = "snack"
}

-- Equipment types
Crafting.EQUIPMENT_TYPES = {
    PENDANT = "pendant",
    BRACELET = "bracelet",
    WRAP = "wrap"
}

-- Consumable recipes (based on Data_Specs.md)
Crafting.CONSUMABLE_RECIPES = {
    -- Tea A: Dried Herb×2 → -8% Herbalism gather for 900 steps (260 step cost)
    tea_herbalism = {
        name = "Herbal Tea",
        type = Crafting.CONSUMABLE_TYPES.TEA,
        inputs = {
            {item = "dried_herb", quantity = 2}
        },
        output = {item = "tea_herbalism", quantity = 1},
        stepCost = 260,
        duration = 3.0,
        effect = {
            type = "reduce_cost",
            target = "herbalism_gather",
            amount = 0.08, -- 8% reduction
            duration = 900 -- steps
        },
        description = "Reduces Herbalism gather cost by 8% for 900 steps"
    },
    
    -- Potion A: Pressed Flower×1 + Tumbled Stone×1 → +1 craft queue (next 3) (340 step cost)
    potion_craft_queue = {
        name = "Crafting Potion",
        type = Crafting.CONSUMABLE_TYPES.POTION,
        inputs = {
            {item = "pressed_flower", quantity = 1},
            {item = "tumbled_stone", quantity = 1}
        },
        output = {item = "potion_craft_queue", quantity = 1},
        stepCost = 340,
        duration = 3.5,
        effect = {
            type = "craft_queue",
            amount = 1, -- +1 queue slot
            uses = 3 -- next 3 crafts
        },
        description = "Adds +1 craft queue slot for next 3 crafts"
    },
    
    -- Snack A: Sea Salt×1 + Kelp Flakes×1 → refund 100 steps instantly (220 step cost)
    snack_step_refund = {
        name = "Kelp Snack",
        type = Crafting.CONSUMABLE_TYPES.SNACK,
        inputs = {
            {item = "sea_salt", quantity = 1},
            {item = "kelp_flakes", quantity = 1}
        },
        output = {item = "snack_step_refund", quantity = 1},
        stepCost = 220,
        duration = 2.5,
        effect = {
            type = "instant_refund",
            amount = 100 -- steps refunded
        },
        description = "Instantly refunds 100 steps to bank"
    }
}

-- Equipment recipes (based on Data_Specs.md)
Crafting.EQUIPMENT_RECIPES = {
    -- Pendant A: Pressed Flower×1 + Polished Crystal×1 → -6% steps on equipment crafts (420 step cost)
    pendant_craft_reduction = {
        name = "Flower Pendant",
        type = Crafting.EQUIPMENT_TYPES.PENDANT,
        inputs = {
            {item = "pressed_flower", quantity = 1},
            {item = "polished_crystal", quantity = 1}
        },
        output = {item = "pendant_craft_reduction", quantity = 1},
        stepCost = 420,
        duration = 4.0,
        effect = {
            type = "reduce_cost",
            target = "equipment_craft",
            amount = 0.06, -- 6% reduction
            permanent = true -- Durable equipment
        },
        description = "Reduces equipment craft costs by 6%"
    },
    
    -- Bracelet A: Dried Herb×2 + Sea Salt×1 → 10% chance +1 item on Herbalism (380 step cost)
    bracelet_herbalism_bonus = {
        name = "Herb Bracelet",
        type = Crafting.EQUIPMENT_TYPES.BRACELET,
        inputs = {
            {item = "dried_herb", quantity = 2},
            {item = "sea_salt", quantity = 1}
        },
        output = {item = "bracelet_herbalism_bonus", quantity = 1},
        stepCost = 380,
        duration = 3.8,
        effect = {
            type = "bonus_chance",
            target = "herbalism_gather",
            chance = 0.10, -- 10% chance
            bonus = 1, -- +1 item
            permanent = true
        },
        description = "10% chance for +1 herb when gathering"
    },
    
    -- Wrap A: Kelp Flakes×2 + Polished Crystal×2 → -6% steps on polish (520 step cost)
    wrap_polish_reduction = {
        name = "Crystal Wrap",
        type = Crafting.EQUIPMENT_TYPES.WRAP,
        inputs = {
            {item = "kelp_flakes", quantity = 2},
            {item = "polished_crystal", quantity = 2}
        },
        output = {item = "wrap_polish_reduction", quantity = 1},
        stepCost = 520,
        duration = 4.5,
        effect = {
            type = "reduce_cost",
            target = "crystal_polish",
            amount = 0.06, -- 6% reduction
            permanent = true
        },
        description = "Reduces crystal polish cost by 6%"
    }
}

-- Get all recipes (consumables + equipment)
function Crafting.getAllRecipes()
    local all = {}
    for id, recipe in pairs(Crafting.CONSUMABLE_RECIPES) do
        all[id] = recipe
    end
    for id, recipe in pairs(Crafting.EQUIPMENT_RECIPES) do
        all[id] = recipe
    end
    return all
end

-- Check if can craft recipe
function Crafting.canCraft(recipeId, inventory)
    local recipe = Crafting.CONSUMABLE_RECIPES[recipeId] or Crafting.EQUIPMENT_RECIPES[recipeId]
    if not recipe then
        return false, "Invalid recipe"
    end
    
    -- Check inputs
    for _, input in ipairs(recipe.inputs) do
        local count = inventory.getItemCount(input.item)
        if count < input.quantity then
            return false, string.format("Need %d %s, have %d", input.quantity, input.item, count)
        end
    end
    
    return true, nil
end

-- Perform craft (without spending steps - steps already spent by ActionRunner)
function Crafting.performCraft(recipeId, inventory, stepSystem)
    local recipe = Crafting.CONSUMABLE_RECIPES[recipeId] or Crafting.EQUIPMENT_RECIPES[recipeId]
    if not recipe then
        return false, "Invalid recipe"
    end
    
    -- Check requirements
    local canCraft, errorMsg = Crafting.canCraft(recipeId, inventory)
    if not canCraft then
        return false, errorMsg
    end
    
    -- Note: Steps are spent by ActionRunner before this is called
    
    -- Remove inputs
    for _, input in ipairs(recipe.inputs) do
        inventory.removeItem(input.item, input.quantity)
    end
    
    -- Add output
    inventory.addItem(recipe.output.item, recipe.output.quantity)
    
    return true, string.format("Crafted %s!", recipe.name)
end

-- Get craft action data
function Crafting.getCraftAction(recipeId)
    local recipe = Crafting.CONSUMABLE_RECIPES[recipeId] or Crafting.EQUIPMENT_RECIPES[recipeId]
    if not recipe then
        return nil
    end
    
    return {
        name = "Crafting " .. recipe.name,
        type = "craft",
        recipeId = recipeId,
        stepCost = recipe.stepCost,
        duration = recipe.duration
    }
end

return Crafting


