-- Progression System Module
-- Tracks milestones, completions, and unlocks (based on Progression.md)

local Progression = {}

-- Progression data
Progression.data = {
    herbalism = {
        gatherCount = 0,
        liveStepsSpent = 0,
        transformCount = 0
    },
    crystal = {
        gatherCount = 0,
        liveStepsSpent = 0,
        transformCount = 0
    },
    shores = {
        gatherCount = 0,
        liveStepsSpent = 0,
        transformCount = 0
    },
    consumables = {
        craftCount = 0,
        bankedStepsSpent = 0
    },
    equipment = {
        craftCount = 0,
        bankedStepsSpent = 0
    }
}

-- Milestone definitions (based on Progression.md)
Progression.MILESTONES = {
    -- Herbalism milestones
    herbalism_transform_unlock = {
        path = "herbalism",
        name = "Herbalism Transform Unlock",
        requirement = {gatherCount = 10, liveStepsSpent = 1500},
        unlocks = "herbalism_transforms",
        description = "Unlock herb drying and pressing"
    },
    herbalism_bundle_node = {
        path = "herbalism",
        name = "Herbalism Bundle Node",
        requirement = {gatherCount = 40, liveStepsSpent = 6000},
        unlocks = "herbalism_bundle_node",
        description = "Unlock herb bundle crafting node"
    },
    
    -- Crystal milestones
    crystal_transform_unlock = {
        path = "crystal",
        name = "Crystal Transform Unlock",
        requirement = {gatherCount = 8, liveStepsSpent = 1200},
        unlocks = "crystal_transforms",
        description = "Unlock crystal polishing and tumbling"
    },
    crystal_extra_outcrop = {
        path = "crystal",
        name = "Extra Outcrop",
        requirement = {gatherCount = 30, liveStepsSpent = 5000},
        unlocks = "crystal_extra_node",
        description = "Unlock additional crystal outcrop"
    },
    
    -- Shores milestones
    shores_transform_unlock = {
        path = "shores",
        name = "Shores Transform Unlock",
        requirement = {gatherCount = 8, liveStepsSpent = 1200},
        unlocks = "shores_transforms",
        description = "Unlock salt extraction and kelp pressing"
    },
    shores_kelp_press = {
        path = "shores",
        name = "Kelp Press Node",
        requirement = {gatherCount = 30, liveStepsSpent = 5000},
        unlocks = "shores_kelp_node",
        description = "Unlock kelp pressing station"
    },
    
    -- Consumables milestones
    consumables_brew_stand = {
        path = "consumables",
        name = "Brew Stand",
        requirement = {craftCount = 1, bankedStepsSpent = 800},
        unlocks = "brew_stand",
        description = "Unlock advanced tea brewing"
    },
    consumables_snack_prep = {
        path = "consumables",
        name = "Snack Prep Station",
        requirement = {craftCount = 3, bankedStepsSpent = 2400},
        unlocks = "snack_prep",
        description = "Unlock snack preparation station"
    },
    
    -- Equipment milestones
    equipment_threadwork = {
        path = "equipment",
        name = "Threadwork Station",
        requirement = {craftCount = 1, bankedStepsSpent = 900},
        unlocks = "threadwork",
        description = "Unlock advanced fabric crafting"
    },
    equipment_wirework = {
        path = "equipment",
        name = "Wirework Station",
        requirement = {craftCount = 3, bankedStepsSpent = 2700},
        unlocks = "wirework",
        description = "Unlock advanced wire crafting"
    }
}

-- Unlocked features
Progression.unlocked = {}

-- Initialize progression system
function Progression.init()
    Progression.data = {
        herbalism = {gatherCount = 0, liveStepsSpent = 0, transformCount = 0},
        crystal = {gatherCount = 0, liveStepsSpent = 0, transformCount = 0},
        shores = {gatherCount = 0, liveStepsSpent = 0, transformCount = 0},
        consumables = {craftCount = 0, bankedStepsSpent = 0},
        equipment = {craftCount = 0, bankedStepsSpent = 0}
    }
    Progression.unlocked = {}
    print("Progression system initialized")
end

-- Record a gather completion
function Progression.recordGather(pathName, stepsSpent)
    if Progression.data[pathName] then
        Progression.data[pathName].gatherCount = Progression.data[pathName].gatherCount + 1
        Progression.data[pathName].liveStepsSpent = Progression.data[pathName].liveStepsSpent + stepsSpent
        Progression.checkMilestones(pathName)
    end
end

-- Record a transform completion
function Progression.recordTransform(pathName, stepsSpent)
    if Progression.data[pathName] then
        Progression.data[pathName].transformCount = Progression.data[pathName].transformCount + 1
        Progression.checkMilestones(pathName)
    end
end

-- Record a craft completion
function Progression.recordCraft(craftType, stepsSpent)
    if Progression.data[craftType] then
        Progression.data[craftType].craftCount = Progression.data[craftType].craftCount + 1
        Progression.data[craftType].bankedStepsSpent = Progression.data[craftType].bankedStepsSpent + stepsSpent
        Progression.checkMilestones(craftType)
    end
end

-- Check if milestones are reached
function Progression.checkMilestones(pathName)
    for milestoneId, milestone in pairs(Progression.MILESTONES) do
        if milestone.path == pathName and not Progression.unlocked[milestoneId] then
            local pathData = Progression.data[pathName]
            local req = milestone.requirement
            
            -- Check if requirements are met (OR condition)
            local gatherMet = not req.gatherCount or pathData.gatherCount >= req.gatherCount
            local stepsMet = not req.liveStepsSpent or pathData.liveStepsSpent >= req.liveStepsSpent
            local craftMet = not req.craftCount or pathData.craftCount >= req.craftCount
            local bankedMet = not req.bankedStepsSpent or pathData.bankedStepsSpent >= req.bankedStepsSpent
            
            if (gatherMet or stepsMet) and (craftMet or bankedMet) then
                Progression.unlocked[milestoneId] = true
                print(string.format("MILESTONE UNLOCKED: %s!", milestone.name))
                print(string.format("  -> %s", milestone.description))
            end
        end
    end
end

-- Check if a feature is unlocked
function Progression.isUnlocked(featureId)
    return Progression.unlocked[featureId] == true
end

-- Get progression stats
function Progression.getStats()
    return Progression.data
end

-- Get unlocked milestones
function Progression.getUnlockedMilestones()
    local unlocked = {}
    for milestoneId, _ in pairs(Progression.unlocked) do
        table.insert(unlocked, Progression.MILESTONES[milestoneId])
    end
    return unlocked
end

-- Get progress toward next milestone for a path
function Progression.getNextMilestone(pathName)
    for milestoneId, milestone in pairs(Progression.MILESTONES) do
        if milestone.path == pathName and not Progression.unlocked[milestoneId] then
            local pathData = Progression.data[pathName]
            local req = milestone.requirement
            
            return {
                milestone = milestone,
                currentGathers = pathData.gatherCount or 0,
                requiredGathers = req.gatherCount or 0,
                currentSteps = pathData.liveStepsSpent or pathData.bankedStepsSpent or 0,
                requiredSteps = req.liveStepsSpent or req.bankedStepsSpent or 0
            }
        end
    end
    
    return nil -- All milestones unlocked
end

-- Reset progression
function Progression.reset()
    Progression.init()
    print("Progression reset")
end

return Progression

