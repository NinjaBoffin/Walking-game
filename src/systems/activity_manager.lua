-- Activity Manager Module
-- Manages activity selection, configuration, and execution

local ActivityManager = {}

-- Activity state
ActivityManager.currentActivity = nil
ActivityManager.activityState = "selection" -- "selection", "configuring", "active", "completing"
ActivityManager.pendingActivityType = nil
ActivityManager.quantityInput = ""

-- Activity types and their base costs
ActivityManager.ACTIVITY_TYPES = {
    -- Gathering activities (use live steps)
    gather_herbalism = {
        name = "Gather Herbs",
        type = "gather",
        path = "herbalism",
        item = "herb",
        stepsPerItem = 100,
        usesLiveSteps = true,
        requiresLocation = true
    },
    gather_crystal = {
        name = "Gather Crystals",
        type = "gather",
        path = "crystal",
        item = "crystal_shard",
        stepsPerItem = 120,
        usesLiveSteps = true,
        requiresLocation = true
    },
    gather_shores = {
        name = "Gather Shells",
        type = "gather",
        path = "shores",
        item = "shell",
        stepsPerItem = 110,
        usesLiveSteps = true,
        requiresLocation = true
    },
    
    -- Transform activities (use banked steps, instant)
    transform_dry = {
        name = "Dry Herbs",
        type = "transform",
        path = "herbalism",
        transformType = "DRY",
        stepCost = 120,
        usesLiveSteps = false,
        requiresLocation = false
    },
    transform_press_herb = {
        name = "Press Flowers",
        type = "transform",
        path = "herbalism",
        transformType = "PRESS",
        stepCost = 150,
        usesLiveSteps = false,
        requiresLocation = false
    },
    transform_polish = {
        name = "Polish Crystals",
        type = "transform",
        path = "crystal",
        transformType = "POLISH",
        stepCost = 150,
        usesLiveSteps = false,
        requiresLocation = false
    },
    transform_tumble = {
        name = "Tumble Stones",
        type = "transform",
        path = "crystal",
        transformType = "TUMBLE",
        stepCost = 180,
        usesLiveSteps = false,
        requiresLocation = false
    },
    transform_salt = {
        name = "Extract Salt",
        type = "transform",
        path = "shores",
        transformType = "SALT",
        stepCost = 140,
        usesLiveSteps = false,
        requiresLocation = false
    },
    transform_press_kelp = {
        name = "Press Kelp",
        type = "transform",
        path = "shores",
        transformType = "PRESS",
        stepCost = 160,
        usesLiveSteps = false,
        requiresLocation = false
    }
}

-- Initialize activity manager
function ActivityManager.init()
    ActivityManager.currentActivity = nil
    ActivityManager.activityState = "selection"
    ActivityManager.pendingActivityType = nil
    ActivityManager.quantityInput = ""
end

-- Get available activities at current location
function ActivityManager.getAvailableActivities(World)
    local available = {}
    local availablePaths = World.getAvailableGatherPaths()
    
    -- Add gathering activities for available paths
    for _, path in ipairs(availablePaths) do
        local activityId = "gather_" .. path
        if ActivityManager.ACTIVITY_TYPES[activityId] then
            table.insert(available, {
                id = activityId,
                data = ActivityManager.ACTIVITY_TYPES[activityId],
                category = "Gathering"
            })
        end
    end
    
    return available
end

-- Get all transform activities
function ActivityManager.getTransformActivities()
    local transforms = {}
    for id, data in pairs(ActivityManager.ACTIVITY_TYPES) do
        if data.type == "transform" then
            table.insert(transforms, {
                id = id,
                data = data
            })
        end
    end
    return transforms
end

-- Start configuring an activity
function ActivityManager.startConfiguration(activityId)
    ActivityManager.pendingActivityType = activityId
    ActivityManager.quantityInput = ""
    ActivityManager.activityState = "configuring"
end

-- Add digit to quantity input
function ActivityManager.addQuantityDigit(digit)
    if #ActivityManager.quantityInput < 2 then -- Max 99
        ActivityManager.quantityInput = ActivityManager.quantityInput .. digit
    end
end

-- Remove last digit from quantity input
function ActivityManager.removeQuantityDigit()
    if #ActivityManager.quantityInput > 0 then
        ActivityManager.quantityInput = ActivityManager.quantityInput:sub(1, -2)
    end
end

-- Confirm and start activity
function ActivityManager.confirmActivity()
    local quantity = tonumber(ActivityManager.quantityInput)
    if not quantity or quantity < 1 then
        return false, "Invalid quantity"
    end
    
    local activityData = ActivityManager.ACTIVITY_TYPES[ActivityManager.pendingActivityType]
    if not activityData then
        return false, "Invalid activity"
    end
    
    -- Create activity instance
    ActivityManager.currentActivity = {
        id = ActivityManager.pendingActivityType,
        name = activityData.name,
        type = activityData.type,
        path = activityData.path,
        targetQuantity = quantity,
        completedQuantity = 0,
        stepsAccumulated = 0,
        data = activityData
    }
    
    -- Calculate total steps needed for gathering
    if activityData.type == "gather" then
        ActivityManager.currentActivity.totalStepsNeeded = quantity * activityData.stepsPerItem
    end
    
    ActivityManager.activityState = "active"
    ActivityManager.pendingActivityType = nil
    ActivityManager.quantityInput = ""
    
    return true, "Activity started"
end

-- Cancel configuration
function ActivityManager.cancelConfiguration()
    ActivityManager.pendingActivityType = nil
    ActivityManager.quantityInput = ""
    ActivityManager.activityState = "selection"
end

-- Update active activity progress (called from action completion)
function ActivityManager.updateProgress(itemsGained, stepsUsed)
    if not ActivityManager.currentActivity then
        return
    end
    
    ActivityManager.currentActivity.completedQuantity = ActivityManager.currentActivity.completedQuantity + itemsGained
    ActivityManager.currentActivity.stepsAccumulated = ActivityManager.currentActivity.stepsAccumulated + stepsUsed
end

-- Check if activity is complete
function ActivityManager.isActivityComplete()
    if not ActivityManager.currentActivity then
        return false
    end
    
    return ActivityManager.currentActivity.completedQuantity >= ActivityManager.currentActivity.targetQuantity
end

-- Complete current activity
function ActivityManager.completeActivity()
    ActivityManager.currentActivity = nil
    ActivityManager.activityState = "selection"
end

-- Cancel current activity (refund steps to bank)
function ActivityManager.cancelActivity(StepSystem)
    if not ActivityManager.currentActivity then
        return false, "No active activity"
    end
    
    -- Refund accumulated live steps to bank
    if ActivityManager.currentActivity.stepsAccumulated > 0 then
        StepSystem.addToBank(ActivityManager.currentActivity.stepsAccumulated)
        print(string.format("Refunded %d steps to bank", ActivityManager.currentActivity.stepsAccumulated))
    end
    
    ActivityManager.currentActivity = nil
    ActivityManager.activityState = "selection"
    
    return true, "Activity cancelled"
end

-- Get current activity info
function ActivityManager.getCurrentActivity()
    return ActivityManager.currentActivity
end

-- Get activity state
function ActivityManager.getState()
    return ActivityManager.activityState
end

-- Get pending activity type
function ActivityManager.getPendingActivityType()
    return ActivityManager.pendingActivityType
end

-- Get quantity input
function ActivityManager.getQuantityInput()
    return ActivityManager.quantityInput
end

-- Reset activity manager
function ActivityManager.reset()
    ActivityManager.init()
end

return ActivityManager

