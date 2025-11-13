-- Action Runner Module
-- Handles action state machine: idle → gather_active/spend_active → complete → idle

local ActionRunner = {}

ActionRunner.STATES = {
    IDLE = "idle",
    GATHER_ACTIVE = "gather_active",
    SPEND_ACTIVE = "spend_active",
    COMPLETE = "complete"
}

ActionRunner.currentState = ActionRunner.STATES.IDLE
ActionRunner.currentAction = nil
ActionRunner.progress = 0
ActionRunner.requiredSteps = 0
ActionRunner.stepsAccumulated = 0

-- Initialize action runner
function ActionRunner.init()
    ActionRunner.currentState = ActionRunner.STATES.IDLE
    ActionRunner.currentAction = nil
    ActionRunner.progress = 0
    ActionRunner.requiredSteps = 0
    ActionRunner.stepsAccumulated = 0
end

-- Start a gather action (uses live steps)
function ActionRunner.startGather(action, stepSystem, Equipment)
    if ActionRunner.currentState ~= ActionRunner.STATES.IDLE then
        return false, "Action already in progress"
    end
    
    -- Calculate cost with equipment reduction
    local baseCost = action.stepCost
    local finalCost = baseCost
    
    if Equipment then
        local reduction = Equipment.getCostReduction("gather")
        finalCost = math.ceil(baseCost * (1 - reduction))
        if reduction > 0 then
            print(string.format("Equipment reduces cost by %d%% (%d → %d)", 
                math.floor(reduction * 100), baseCost, finalCost))
        end
    end
    
    ActionRunner.currentAction = action
    ActionRunner.currentState = ActionRunner.STATES.GATHER_ACTIVE
    ActionRunner.progress = 0
    ActionRunner.requiredSteps = finalCost
    ActionRunner.stepsAccumulated = 0
    
    print(string.format("Started %s (requires %d live steps)", action.name, finalCost))
    return true
end

-- Start a spend action (uses banked steps, fallback to live)
function ActionRunner.startSpend(action, stepSystem, Equipment, actionType)
    if ActionRunner.currentState ~= ActionRunner.STATES.IDLE then
        return false, "Action already in progress"
    end
    
    -- Calculate cost with equipment reduction
    local baseCost = action.stepCost
    local finalCost = baseCost
    
    if Equipment and actionType then
        local reduction = Equipment.getCostReduction(actionType)
        finalCost = math.ceil(baseCost * (1 - reduction))
        if reduction > 0 then
            print(string.format("Equipment reduces cost by %d%% (%d → %d)", 
                math.floor(reduction * 100), baseCost, finalCost))
        end
    end
    
    -- Check if we have enough steps
    local counts = stepSystem.getCounts()
    if counts.bank + counts.live < finalCost then
        return false, string.format("Need %d steps, have %d banked + %d live", 
            finalCost, counts.bank, counts.live)
    end
    
    ActionRunner.currentAction = action
    ActionRunner.currentState = ActionRunner.STATES.SPEND_ACTIVE
    ActionRunner.progress = 0
    ActionRunner.requiredSteps = finalCost
    ActionRunner.stepsAccumulated = 0
    
    print(string.format("Started %s (requires %d steps)", action.name, finalCost))
    return true
end

-- Update action progress
function ActionRunner.update(dt, stepSystem)
    if ActionRunner.currentState == ActionRunner.STATES.IDLE then
        return
    end
    
    if not ActionRunner.currentAction then
        ActionRunner.currentState = ActionRunner.STATES.IDLE
        return
    end
    
    -- For gather actions, accumulate live steps
    if ActionRunner.currentState == ActionRunner.STATES.GATHER_ACTIVE then
        local counts = stepSystem.getCounts()
        local availableSteps = counts.live
        
        if availableSteps > 0 then
            local stepsToUse = math.min(availableSteps, ActionRunner.requiredSteps - ActionRunner.stepsAccumulated)
            ActionRunner.stepsAccumulated = ActionRunner.stepsAccumulated + stepsToUse
            
            -- Spend the live steps (don't use print statements in spend function)
            stepSystem.liveSteps = stepSystem.liveSteps - stepsToUse
            
            ActionRunner.progress = ActionRunner.stepsAccumulated / ActionRunner.requiredSteps
        else
            -- No live steps available, progress stalls
            ActionRunner.progress = ActionRunner.stepsAccumulated / ActionRunner.requiredSteps
        end
        
        -- Complete when enough steps accumulated
        if ActionRunner.progress >= 1.0 then
            -- Action completes, return action data
            return ActionRunner.complete(stepSystem)
        end
    end
    
    -- For spend actions, use time-based progress
    if ActionRunner.currentState == ActionRunner.STATES.SPEND_ACTIVE then
        ActionRunner.progress = ActionRunner.progress + (dt / ActionRunner.currentAction.duration)
        
        if ActionRunner.progress >= 1.0 then
            -- Spend steps when action completes (for spend actions)
            local counts = stepSystem.getCounts()
            if counts.bank >= ActionRunner.requiredSteps then
                stepSystem.spend(ActionRunner.requiredSteps, false)
            else
                -- Use bank first, then live fallback
                local fromBank = counts.bank
                local fromLive = ActionRunner.requiredSteps - fromBank
                if fromBank > 0 then
                    stepSystem.spend(fromBank, false)
                end
                if fromLive > 0 then
                    stepSystem.spend(fromLive, true)
                end
            end
            
            -- Return completed action
            return ActionRunner.complete(stepSystem)
        end
    end
    
    return nil
end

-- Complete current action (returns action data before clearing)
function ActionRunner.complete(stepSystem)
    if ActionRunner.currentState == ActionRunner.STATES.IDLE then
        return nil
    end
    
    ActionRunner.currentState = ActionRunner.STATES.COMPLETE
    
    -- Save action data before clearing
    local completedAction = ActionRunner.currentAction
    
    -- Return to idle
    ActionRunner.currentState = ActionRunner.STATES.IDLE
    ActionRunner.currentAction = nil
    ActionRunner.progress = 0
    ActionRunner.requiredSteps = 0
    ActionRunner.stepsAccumulated = 0
    
    return completedAction
end

-- Cancel current action
function ActionRunner.cancel()
    ActionRunner.currentState = ActionRunner.STATES.IDLE
    ActionRunner.currentAction = nil
    ActionRunner.progress = 0
    ActionRunner.requiredSteps = 0
    ActionRunner.stepsAccumulated = 0
    print("Action cancelled")
end

-- Get current action info
function ActionRunner.getCurrentAction()
    return {
        state = ActionRunner.currentState,
        action = ActionRunner.currentAction,
        progress = ActionRunner.progress,
        stepsAccumulated = ActionRunner.stepsAccumulated,
        requiredSteps = ActionRunner.requiredSteps
    }
end

-- Check if idle
function ActionRunner.isIdle()
    return ActionRunner.currentState == ActionRunner.STATES.IDLE
end

return ActionRunner

