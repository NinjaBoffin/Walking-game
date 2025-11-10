-- Step System Module
-- Handles step bank, accumulation, and spending

local StepSystem = {}

StepSystem.bank = 0
StepSystem.liveSteps = 0
StepSystem.isSimulating = true -- For prototype testing

-- Configuration
StepSystem.config = {
    simulationRate = 10, -- steps per second when simulating
    minTransformCost = 120,
    maxTransformCost = 220,
    minGatherCost = 90,
    maxGatherCost = 140
}

-- Initialize the step system
function StepSystem.init()
    StepSystem.bank = 0
    StepSystem.liveSteps = 0
    print("Step System initialized")
end

-- Add steps to the bank (for idle accumulation)
function StepSystem.addToBank(amount)
    StepSystem.bank = StepSystem.bank + amount
    print(string.format("Added %.0f steps to bank. Total: %.0f", amount, StepSystem.bank))
end

-- Spend steps from bank (fallback to live if insufficient)
function StepSystem.spend(amount, allowLiveFallback)
    if StepSystem.bank >= amount then
        StepSystem.bank = StepSystem.bank - amount
        print(string.format("Spent %.0f steps from bank. Remaining: %.0f", amount, StepSystem.bank))
        return true
    elseif allowLiveFallback and StepSystem.liveSteps >= amount then
        StepSystem.liveSteps = StepSystem.liveSteps - amount
        print(string.format("Spent %.0f live steps. Remaining: %.0f", amount, StepSystem.liveSteps))
        return true
    else
        print(string.format("Insufficient steps! Need %.0f, have %.0f banked + %.0f live", 
            amount, StepSystem.bank, StepSystem.liveSteps))
        return false
    end
end

-- Add live steps (for gathering)
function StepSystem.addLiveSteps(amount)
    StepSystem.liveSteps = StepSystem.liveSteps + amount
    print(string.format("Added %.0f live steps. Total: %.0f", amount, StepSystem.liveSteps))
end

-- Get current step counts
function StepSystem.getCounts()
    return {
        bank = StepSystem.bank,
        live = StepSystem.liveSteps
    }
end

-- Simulate step accumulation (for prototype)
-- 10x faster for testing
function StepSystem.updateSimulation(dt)
    if StepSystem.isSimulating then
        -- For prototype: simulate both bank accumulation and live steps
        -- In real game, live steps come from sensors during active gathering
        -- 10x multiplier for faster testing
        StepSystem.bank = StepSystem.bank + (StepSystem.config.simulationRate * dt * 10)
    end
end

-- Simulate live steps (for prototype testing - simulates walking during gather)
-- 10x faster for testing
function StepSystem.simulateLiveSteps(dt, rate)
    rate = rate or StepSystem.config.simulationRate
    -- 10x multiplier for faster testing
    StepSystem.liveSteps = StepSystem.liveSteps + (rate * dt * 10)
end

-- Reset system
function StepSystem.reset()
    StepSystem.bank = 0
    StepSystem.liveSteps = 0
    print("Step System reset")
end

return StepSystem
