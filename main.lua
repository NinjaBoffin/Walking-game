-- Walking RPG - Minimal Prototype
-- Main game file

local StepSystem = require("src.systems.step_system")
local Inventory = require("src.systems.inventory")
local Herbalism = require("src.paths.herbalism")
local Crystal = require("src.paths.crystal")
local Shores = require("src.paths.shores")
local ActionRunner = require("src.systems.action_runner")
local Crafting = require("src.systems.crafting")
local Equipment = require("src.systems.equipment")
local World = require("src.systems.world")
local Progression = require("src.systems.progression")
local ActivityManager = require("src.systems.activity_manager")
local Button = require("src.ui.button")

local game = {
    state = "playing",
    showHelp = false,
    showCrafting = false,
    showTravel = false,
    craftingCategory = "consumables", -- "consumables" or "equipment"
    selectedRecipe = 1,
    mouseX = 0,
    mouseY = 0
}

-- UI Helper functions
function drawBox(x, y, width, height, title)
    -- Draw border
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", x+2, y+2, width-4, height-4)
    
    -- Draw title bar if provided
    if title then
        love.graphics.setColor(0.2, 0.4, 0.6)
        love.graphics.rectangle("fill", x+2, y+2, width-4, 24)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(title, x+8, y+6)
    end
    
    love.graphics.setColor(1, 1, 1)
end

function drawModal(x, y, width, height, title)
    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw modal box
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0.4, 0.6, 0.8)
    love.graphics.rectangle("line", x, y, width, height, 2)
    
    -- Draw title bar
    love.graphics.setColor(0.3, 0.5, 0.7)
    love.graphics.rectangle("fill", x, y, width, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(title, x+10, y+8)
    
    love.graphics.setColor(1, 1, 1)
end

-- Game configuration
function love.conf(t)
    t.window.title = "Walking RPG Prototype"
    t.window.width = 900
    t.window.height = 600
    t.window.resizable = true
    t.console = true -- Enable console for debugging
end

-- Initialize game
function love.load()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
    love.graphics.setColor(1, 1, 1)
    
    -- Initialize all systems
    StepSystem.init()
    Inventory.init()
    ActionRunner.init()
    Equipment.init()
    World.init()
    Progression.init()
    ActivityManager.init()
    
    print("Walking RPG Prototype loaded!")
    print("Controls:")
    print("  SPACE - Simulate steps (adds to bank)")
    print("  1 - Gather herbs | 2 - Gather crystals | 3 - Gather shells")
    print("  Q - Dry herbs | W - Press flowers")
    print("  E - Polish crystal | R - Tumble stones")
    print("  A - Extract salt | S - Press kelp")
    print("  C - Open Crafting Menu | T - Open Travel Map")
    print("  H - Toggle Help/Recipes")
    print("  X - Reset game")
end

-- Update game state
function love.update(dt)
    -- Update mouse position
    game.mouseX, game.mouseY = love.mouse.getPosition()
    Button.updateHover(game.mouseX, game.mouseY)
    
    -- Simulate step accumulation (for prototype)
    if love.keyboard.isDown("space") then
        StepSystem.updateSimulation(dt)
    end
    
    -- Simulate live steps when gathering (for prototype)
    local actionInfo = ActionRunner.getCurrentAction()
    if actionInfo and actionInfo.state == "gather_active" then
        StepSystem.simulateLiveSteps(dt, 15) -- Faster rate for gathering simulation
    end
    
    -- Update action runner and handle completion
    local completedAction = ActionRunner.update(dt, StepSystem)
    if completedAction then
        handleActionComplete(completedAction)
    end
    
    -- Check if activity is complete
    if ActivityManager.getState() == "active" and ActivityManager.isActivityComplete() then
        ActivityManager.completeActivity()
        print("Activity completed!")
    end
end

-- Draw game state
function love.draw()
    local activityState = ActivityManager.getState()
    
    if activityState == "selection" then
        drawActivitySelectionScreen()
    elseif activityState == "configuring" then
        drawActivityConfigurationScreen()
    elseif activityState == "active" then
        drawActiveActivityScreen()
    end
    
    -- Modals draw on top of any screen
    if game.showHelp then
        drawHelpModal()
    elseif game.showTravel then
        drawTravelModal()
    end
end

-- Draw activity selection screen
function drawActivitySelectionScreen()
    Button.clear()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Header
    drawBox(10, 10, screenW-20, 80, "Walking RPG")
    local y = 42
    local counts = StepSystem.getCounts()
    love.graphics.print(string.format("Banked Steps: %.0f", counts.bank), 20, y)
    y = y + 20
    local currentNode = World.getCurrentNode()
    love.graphics.print(string.format("Location: %s (%s)", currentNode.name, currentNode.region), 20, y)
    
    -- Activity selection area
    y = 110
    drawBox(10, y, screenW-20, screenH-y-10, "Select Activity")
    y = y + 35
    
    local activities = ActivityManager.getAvailableActivities(World)
    local currentCategory = ""
    local buttonY = y
    local buttonX = 30
    local buttonWidth = screenW - 60
    local buttonHeight = 50
    
    for i, activity in ipairs(activities) do
        -- Category header
        if activity.category ~= currentCategory then
            currentCategory = activity.category
            love.graphics.setColor(0.8, 0.9, 1)
            love.graphics.print(currentCategory, buttonX, buttonY)
            love.graphics.setColor(1, 1, 1)
            buttonY = buttonY + 25
        end
        
        -- Create button
        local btn = Button.create(
            activity.id,
            buttonX,
            buttonY,
            buttonWidth,
            buttonHeight,
            activity.data.name,
            function()
                if activity.id == "travel" then
                    game.showTravel = true
                else
                    ActivityManager.startConfiguration(activity.id)
                end
            end
        )
        Button.register(btn)
        Button.draw(btn)
        
        -- Show step cost
        if activity.data.stepsPerItem then
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print(string.format("%d steps per item", activity.data.stepsPerItem), buttonX + 10, buttonY + 30)
            love.graphics.setColor(1, 1, 1)
        elseif activity.data.stepCost then
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print(string.format("%d steps per action", activity.data.stepCost), buttonX + 10, buttonY + 30)
            love.graphics.setColor(1, 1, 1)
        end
        
        buttonY = buttonY + buttonHeight + 10
    end
    
    -- Instructions
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("SPACE - Simulate steps  |  H - Help  |  X - Reset", 20, screenH - 25)
    love.graphics.setColor(1, 1, 1)
end

-- Draw activity configuration screen
function drawActivityConfigurationScreen()
    Button.clear()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    local activityId = ActivityManager.getPendingActivityType()
    local activityData = ActivityManager.ACTIVITY_TYPES[activityId]
    
    if not activityData then
        ActivityManager.cancelConfiguration()
        return
    end
    
    -- Header
    drawBox(10, 10, screenW-20, 80, activityData.name)
    local y = 50
    love.graphics.print("How many would you like to complete?", 20, y)
    
    -- Quantity input area
    y = 110
    drawBox(10, y, screenW-20, 200, "Quantity")
    y = y + 40
    
    local quantityInput = ActivityManager.getQuantityInput()
    local quantity = tonumber(quantityInput) or 0
    
    -- Display input
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", screenW/2 - 100, y, 200, 50)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", screenW/2 - 100, y, 200, 50)
    
    local displayText = quantityInput ~= "" and quantityInput or "0"
    love.graphics.print(displayText, screenW/2 - 10, y + 15)
    
    -- Estimated steps
    y = y + 70
    if quantity > 0 and activityData.stepsPerItem then
        local totalSteps = quantity * activityData.stepsPerItem
        love.graphics.setColor(0.8, 0.9, 1)
        love.graphics.print(string.format("Estimated: %d steps", totalSteps), screenW/2 - 60, y)
        love.graphics.setColor(1, 1, 1)
    end
    
    -- Number pad
    y = 330
    local numPadX = screenW/2 - 120
    local btnSize = 70
    local btnGap = 10
    
    for i = 1, 9 do
        local row = math.floor((i-1) / 3)
        local col = (i-1) % 3
        local btnX = numPadX + col * (btnSize + btnGap)
        local btnY = y + row * (btnSize + btnGap)
        
        local btn = Button.create(
            "num_" .. i,
            btnX,
            btnY,
            btnSize,
            btnSize,
            tostring(i),
            function() ActivityManager.addQuantityDigit(tostring(i)) end
        )
        Button.register(btn)
        Button.draw(btn)
    end
    
    -- Zero button
    local btn0 = Button.create(
        "num_0",
        numPadX + btnSize + btnGap,
        y + 3 * (btnSize + btnGap),
        btnSize,
        btnSize,
        "0",
        function() ActivityManager.addQuantityDigit("0") end
    )
    Button.register(btn0)
    Button.draw(btn0)
    
    -- Backspace button
    local btnBack = Button.create(
        "backspace",
        numPadX + 2 * (btnSize + btnGap),
        y + 3 * (btnSize + btnGap),
        btnSize,
        btnSize,
        "←",
        function() ActivityManager.removeQuantityDigit() end
    )
    Button.register(btnBack)
    Button.draw(btnBack)
    
    -- Action buttons
    y = screenH - 80
    local btnCancel = Button.create(
        "cancel",
        30,
        y,
        200,
        50,
        "Cancel",
        function() ActivityManager.cancelConfiguration() end
    )
    Button.register(btnCancel)
    Button.draw(btnCancel)
    
    local btnConfirm = Button.create(
        "confirm",
        screenW - 230,
        y,
        200,
        50,
        "Start Activity",
        function()
            local success, msg = ActivityManager.confirmActivity()
            if success then
                -- Start the gather action
                local activity = ActivityManager.getCurrentActivity()
                if activity.type == "gather" then
                    local pathModule = pathModules[activity.path]
                    if pathModule then
                        local gatherAction = pathModule.getGatherAction()
                        ActionRunner.startGather(gatherAction, StepSystem)
                    end
                end
            else
                print(msg)
            end
        end
    )
    btnConfirm.enabled = quantity > 0
    Button.register(btnConfirm)
    Button.draw(btnConfirm)
end

-- Draw active activity screen
function drawActiveActivityScreen()
    Button.clear()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    local activity = ActivityManager.getCurrentActivity()
    if not activity then
        ActivityManager.completeActivity()
        return
    end
    
    -- Header
    drawBox(10, 10, screenW-20, 100, "Active Activity")
    local y = 42
    love.graphics.setColor(0.8, 1, 0.8)
    love.graphics.print(activity.name, 20, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 25
    
    local counts = StepSystem.getCounts()
    love.graphics.print(string.format("Banked Steps: %.0f  |  Live Steps: %.0f", counts.bank, counts.live), 20, y)
    
    -- Progress area
    y = 130
    drawBox(10, y, screenW-20, 250, "Progress")
    y = y + 40
    
    -- Items progress
    love.graphics.setColor(0.8, 0.9, 1)
    love.graphics.print(string.format("Items: %d / %d", activity.completedQuantity, activity.targetQuantity), 30, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 30
    
    -- Progress bar for items
    local barWidth = screenW - 60
    local barHeight = 30
    local progress = activity.completedQuantity / activity.targetQuantity
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 30, y, barWidth, barHeight)
    love.graphics.setColor(0.4, 0.7, 0.4)
    love.graphics.rectangle("fill", 30, y, barWidth * progress, barHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 30, y, barWidth, barHeight)
    local progressText = string.format("%d%%", math.floor(progress * 100))
    love.graphics.print(progressText, screenW/2 - 15, y + 7)
    
    y = y + 50
    
    -- Steps progress (for gathering)
    if activity.totalStepsNeeded then
        love.graphics.setColor(0.8, 0.9, 1)
        love.graphics.print(string.format("Steps: %d / %d", activity.stepsAccumulated, activity.totalStepsNeeded), 30, y)
        love.graphics.setColor(1, 1, 1)
        y = y + 30
        
        -- Progress bar for steps
        local stepProgress = math.min(activity.stepsAccumulated / activity.totalStepsNeeded, 1)
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", 30, y, barWidth, barHeight)
        love.graphics.setColor(0.6, 0.8, 0.6)
        love.graphics.rectangle("fill", 30, y, barWidth * stepProgress, barHeight)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", 30, y, barWidth, barHeight)
        local stepProgressText = string.format("%d%%", math.floor(stepProgress * 100))
        love.graphics.print(stepProgressText, screenW/2 - 15, y + 7)
    end
    
    -- Current action status
    y = 400
    drawBox(10, y, screenW-20, 100, "Current Action")
    y = y + 35
    
    local actionInfo = ActionRunner.getCurrentAction()
    if actionInfo.action then
        love.graphics.print(actionInfo.action.name, 30, y)
        y = y + 25
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print(string.format("Progress: %d%%", math.floor(actionInfo.progress * 100)), 30, y)
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("Waiting for next action...", 30, y)
        love.graphics.setColor(1, 1, 1)
    end
    
    -- Cancel button
    y = screenH - 80
    local btnCancel = Button.create(
        "cancel_activity",
        screenW/2 - 100,
        y,
        200,
        50,
        "Cancel Activity",
        function()
            ActivityManager.cancelActivity(StepSystem)
            ActionRunner.cancel()
        end
    )
    Button.register(btnCancel)
    Button.draw(btnCancel)
    
    -- Instructions
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Hold SPACE to simulate steps", 20, screenH - 25)
    love.graphics.setColor(1, 1, 1)
end

-- Draw main game screen (OLD - keeping for reference, will be removed)
function drawGameScreen()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Left column: Steps & Action
    drawBox(10, 10, 280, 200, "Steps & Progress")
    local y = 42
    local counts = StepSystem.getCounts()
    love.graphics.print(string.format("Bank: %.0f steps", counts.bank), 20, y)
    y = y + 20
    love.graphics.print(string.format("Live: %.0f steps", counts.live), 20, y)
    y = y + 25
    
    -- Current location
    local currentNode = World.getCurrentNode()
    love.graphics.setColor(0.8, 1, 0.8)
    love.graphics.print("Location:", 20, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 18
    love.graphics.print(currentNode.name, 20, y)
    y = y + 18
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print(currentNode.region, 20, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 25
    
    -- Current action with progress bar
    local actionInfo = ActionRunner.getCurrentAction()
    if actionInfo.action then
        love.graphics.print(actionInfo.action.name, 20, y)
        y = y + 20
        
        -- Progress bar
        local barWidth = 250
        local barHeight = 20
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", 20, y, barWidth, barHeight)
        love.graphics.setColor(0.4, 0.7, 0.4)
        love.graphics.rectangle("fill", 20, y, barWidth * actionInfo.progress, barHeight)
        love.graphics.setColor(1, 1, 1)
        local progressText = string.format("%d%%", math.floor(actionInfo.progress * 100))
        love.graphics.print(progressText, 20 + barWidth/2 - 15, y + 4)
        y = y + 25
        
        if actionInfo.state == "gather_active" then
            love.graphics.print(string.format("%.0f/%.0f steps", actionInfo.stepsAccumulated, actionInfo.requiredSteps), 20, y)
        end
    else
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("No active action", 20, y)
        love.graphics.setColor(1, 1, 1)
    end
    
    -- Inventory box
    drawBox(10, 220, 280, 360, "Inventory")
    y = 252
    local capacity = Inventory.getCapacityInfo()
    love.graphics.print(string.format("Slots: %d/%d", capacity.used, capacity.max), 20, y)
    y = y + 25
    
    local items = Inventory.getAllItems()
    if next(items) == nil then
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("(empty)", 20, y)
        love.graphics.setColor(1, 1, 1)
    else
        for itemId, quantity in pairs(items) do
            love.graphics.print(string.format("%s: %d", itemId, quantity), 20, y)
            y = y + 18
        end
    end
    
    -- Right column: Controls
    drawBox(300, 10, 580, 570, "Controls")
    y = 42
    
    love.graphics.setColor(0.8, 0.9, 1)
    love.graphics.print("GATHERING (Live Steps)", 310, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 22
    love.graphics.print("1 - Herbs (100)  |  2 - Crystals (120)  |  3 - Shells (110)", 320, y)
    y = y + 30
    
    love.graphics.setColor(1, 0.9, 0.7)
    love.graphics.print("TRANSFORMS (Banked Steps)", 310, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 22
    love.graphics.print("Herbalism:  Q - Dry (120)  |  W - Press (150)", 320, y)
    y = y + 18
    love.graphics.print("Crystal:    E - Polish (150)  |  R - Tumble (180)", 320, y)
    y = y + 18
    love.graphics.print("Shores:     A - Salt (140)  |  S - Kelp (160)", 320, y)
    y = y + 30
    
    love.graphics.setColor(0.8, 1, 0.8)
    love.graphics.print("CRAFTING & TRAVEL", 310, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 22
    love.graphics.print("C - Open Crafting Menu", 320, y)
    y = y + 18
    love.graphics.print("T - Open Travel Map", 320, y)
    y = y + 30
    
    love.graphics.setColor(1, 1, 0.8)
    love.graphics.print("OTHER", 310, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 22
    love.graphics.print("SPACE - Simulate steps (hold)", 320, y)
    y = y + 18
    love.graphics.print("H - Toggle Help/Recipes", 320, y)
    y = y + 18
    love.graphics.print("X - Reset Game", 320, y)
    
    -- Draw crafting modal if open
    if game.showCrafting then
        drawCraftingModal()
    end
end

-- Draw help modal
function drawHelpModal()
    local modalW = 800
    local modalH = 600
    local modalX = (love.graphics.getWidth() - modalW) / 2
    local modalY = (love.graphics.getHeight() - modalH) / 2
    
    drawModal(modalX, modalY, modalW, modalH, "Recipes & Item Guide")
    
    local y = modalY + 45
    local x = modalX + 15
    
    -- Progression section
    love.graphics.setColor(1, 0.9, 0.6)
    love.graphics.print("=== PROGRESSION ===", x, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 22
    
    local stats = Progression.getStats()
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print(string.format("Herbalism: %d gathers, %d transforms, %d steps", 
        stats.herbalism.gatherCount, stats.herbalism.transformCount, stats.herbalism.liveStepsSpent), x, y)
    y = y + 16
    love.graphics.print(string.format("Crystal: %d gathers, %d transforms, %d steps", 
        stats.crystal.gatherCount, stats.crystal.transformCount, stats.crystal.liveStepsSpent), x, y)
    y = y + 16
    love.graphics.print(string.format("Shores: %d gathers, %d transforms, %d steps", 
        stats.shores.gatherCount, stats.shores.transformCount, stats.shores.liveStepsSpent), x, y)
    y = y + 16
    love.graphics.print(string.format("Consumables: %d crafts, %d steps", 
        stats.consumables.craftCount, stats.consumables.bankedStepsSpent), x, y)
    y = y + 16
    love.graphics.print(string.format("Equipment: %d crafts, %d steps", 
        stats.equipment.craftCount, stats.equipment.bankedStepsSpent), x, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 25
    
    -- Herbalism section
    love.graphics.setColor(0.8, 0.9, 1)
    love.graphics.print("HERBALISM PATH (Key: 1)", x, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 22
    love.graphics.print("Gather: herb (100 live steps)", x+15, y)
    y = y + 18
    love.graphics.print("Q - Dry: 2 herb -> 1 dried_herb (120 steps)", x+15, y)
    y = y + 16
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("    Used for consumable crafting", x+15, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 18
    love.graphics.print("W - Press: 3 herb -> 1 pressed_flower (150 steps)", x+15, y)
    y = y + 16
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("    Used for equipment crafting", x+15, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 25
    
    -- Crystal section
    love.graphics.setColor(1, 0.9, 0.7)
    love.graphics.print("CRYSTAL PATH (Key: 2)", x, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 22
    love.graphics.print("Gather: crystal_shard (120 live steps)", x+15, y)
    y = y + 18
    love.graphics.print("E - Polish: 2 shard -> 1 polished_crystal (150 steps)", x+15, y)
    y = y + 16
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("    Used for equipment crafting", x+15, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 18
    love.graphics.print("R - Tumble: 3 shard -> 1 tumbled_stone (180 steps)", x+15, y)
    y = y + 16
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("    Used for consumable crafting", x+15, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 25
    
    -- Shores section
    love.graphics.setColor(0.8, 1, 0.8)
    love.graphics.print("SHORES PATH (Key: 3)", x, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 22
    love.graphics.print("Gather: shell (110 live steps)", x+15, y)
    y = y + 18
    love.graphics.print("A - Extract: 2 shell -> 1 sea_salt (140 steps)", x+15, y)
    y = y + 16
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("    Used for consumable crafting", x+15, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 18
    love.graphics.print("S - Press: 3 shell -> 1 kelp_flakes (160 steps)", x+15, y)
    y = y + 16
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("    Used for consumable crafting", x+15, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 25
    
    -- Crafting section
    love.graphics.setColor(1, 1, 0.8)
    love.graphics.print("CRAFTING (Press C to open menu)", x, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 22
    love.graphics.print("Consumables: Tea, Potion, Snack", x+15, y)
    y = y + 18
    love.graphics.print("Equipment: Pendant, Bracelet, Wrap", x+15, y)
    
    -- Instructions at bottom
    y = modalY + modalH - 30
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Press H or Esc to close", x, y)
    love.graphics.setColor(1, 1, 1)
end

-- Draw travel modal
function drawTravelModal()
    local modalW = 700
    local modalH = 500
    local modalX = (love.graphics.getWidth() - modalW) / 2
    local modalY = (love.graphics.getHeight() - modalH) / 2
    
    drawModal(modalX, modalY, modalW, modalH, "Travel Map")
    
    local y = modalY + 45
    local x = modalX + 15
    
    -- Current location
    local currentNode = World.getCurrentNode()
    love.graphics.setColor(0.8, 1, 0.8)
    love.graphics.print("Current Location:", x, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 22
    love.graphics.print(string.format("%s (%s)", currentNode.name, currentNode.region), x+15, y)
    y = y + 18
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print(currentNode.description, x+15, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 18
    
    -- Available paths at current location
    local availablePaths = World.getAvailableGatherPaths()
    love.graphics.setColor(0.8, 0.9, 1)
    love.graphics.print("Available: " .. table.concat(availablePaths, ", "), x+15, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 35
    
    -- Connections
    love.graphics.setColor(1, 0.9, 0.7)
    love.graphics.print("Travel Destinations:", x, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 25
    
    local connections = World.getConnections()
    local keyIndex = 1
    
    if #connections == 0 then
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("No destinations available", x+15, y)
        love.graphics.setColor(1, 1, 1)
    else
        for _, conn in ipairs(connections) do
            local node = conn.node
            local cost = conn.cost
            
            -- Destination box
            local boxY = y
            local boxH = 70
            love.graphics.setColor(0.25, 0.25, 0.25)
            love.graphics.rectangle("fill", x, boxY, modalW-30, boxH)
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.rectangle("line", x, boxY, modalW-30, boxH)
            
            -- Key and name
            love.graphics.setColor(0.8, 1, 0.8)
            love.graphics.print(string.format("[%d]", keyIndex), x+5, boxY+5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(node.name, x+30, boxY+5)
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print(string.format("(%s)", node.region), x+200, boxY+5)
            
            -- Cost
            local counts = StepSystem.getCounts()
            local canAfford = counts.bank >= cost
            love.graphics.setColor(canAfford and 0.7 or 1, canAfford and 1 or 0.5, canAfford and 0.7 or 0.5)
            love.graphics.print(string.format("Cost: %d steps", cost), x+400, boxY+5)
            love.graphics.setColor(1, 1, 1)
            
            -- Description
            love.graphics.setColor(0.8, 0.9, 1)
            love.graphics.print(node.description, x+10, boxY+25)
            love.graphics.setColor(1, 1, 1)
            
            -- Available paths
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("Paths: " .. table.concat(node.gatherPaths, ", "), x+10, boxY+45)
            love.graphics.setColor(1, 1, 1)
            
            y = y + boxH + 10
            keyIndex = keyIndex + 1
        end
    end
    
    -- Instructions at bottom
    y = modalY + modalH - 30
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("1-9 - Travel to Destination  |  T/Esc - Close", x, y)
    love.graphics.setColor(1, 1, 1)
end

-- Draw crafting modal
function drawCraftingModal()
    local modalW = 700
    local modalH = 500
    local modalX = (love.graphics.getWidth() - modalW) / 2
    local modalY = (love.graphics.getHeight() - modalH) / 2
    
    drawModal(modalX, modalY, modalW, modalH, "Crafting - " .. (game.craftingCategory == "consumables" and "CONSUMABLES" or "EQUIPMENT"))
    
    local y = modalY + 45
    local x = modalX + 15
    
    -- Category tabs
    love.graphics.setColor(game.craftingCategory == "consumables" and 0.4 or 0.25, 
                          game.craftingCategory == "consumables" and 0.6 or 0.35, 
                          game.craftingCategory == "consumables" and 0.8 or 0.45)
    love.graphics.rectangle("fill", x, y, 150, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Consumables", x+25, y+8)
    
    love.graphics.setColor(game.craftingCategory == "equipment" and 0.4 or 0.25, 
                          game.craftingCategory == "equipment" and 0.6 or 0.35, 
                          game.craftingCategory == "equipment" and 0.8 or 0.45)
    love.graphics.rectangle("fill", x+160, y, 150, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Equipment", x+195, y+8)
    
    y = y + 45
    
    -- Recipe list
    local recipes = game.craftingCategory == "consumables" and Crafting.CONSUMABLE_RECIPES or Crafting.EQUIPMENT_RECIPES
    local keyIndex = 1
    
    for recipeId, recipe in pairs(recipes) do
        -- Recipe box
        local boxY = y
        local boxH = 75
        love.graphics.setColor(0.25, 0.25, 0.25)
        love.graphics.rectangle("fill", x, boxY, modalW-30, boxH)
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle("line", x, boxY, modalW-30, boxH)
        
        -- Recipe name and key
        love.graphics.setColor(0.8, 1, 0.8)
        love.graphics.print(string.format("[%d]", keyIndex), x+5, boxY+5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(recipe.name, x+30, boxY+5)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print(string.format("(%d steps)", recipe.stepCost), x+200, boxY+5)
        
        -- Inputs
        love.graphics.setColor(1, 1, 1)
        local inputY = boxY + 25
        love.graphics.print("Needs:", x+10, inputY)
        local inputX = x+60
        for i, input in ipairs(recipe.inputs) do
            local have = Inventory.getItemCount(input.item)
            local hasEnough = have >= input.quantity
            love.graphics.setColor(hasEnough and 0.7 or 1, hasEnough and 1 or 0.5, hasEnough and 0.7 or 0.5)
            love.graphics.print(string.format("%s x%d (%d)", input.item, input.quantity, have), inputX, inputY)
            inputX = inputX + 200
        end
        
        -- Effect
        love.graphics.setColor(0.8, 0.9, 1)
        love.graphics.print(recipe.description, x+10, boxY+45)
        love.graphics.setColor(1, 1, 1)
        
        y = y + boxH + 10
        keyIndex = keyIndex + 1
    end
    
    -- Instructions at bottom
    y = modalY + modalH - 30
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Tab - Switch Category  |  1-9 - Craft Recipe  |  C/Esc - Close", x, y)
    love.graphics.setColor(1, 1, 1)
end

-- Handle mouse clicks
function love.mousepressed(x, y, button)
    if button == 1 then -- Left click
        Button.handleClick(x, y)
    end
end

-- Handle keyboard input
function love.keypressed(key)
    -- Handle modals first
    if game.showHelp then
        if key == "escape" or key == "h" then
            game.showHelp = false
        end
        return
    end
    
    if game.showTravel then
        if key == "escape" or key == "t" then
            game.showTravel = false
        end
        return
    end
    
    -- Toggle help
    if key == "h" then
        game.showHelp = true
        return
    end
    
    -- Toggle travel (only from activity selection screen)
    if key == "t" and ActivityManager.getState() == "selection" then
        game.showTravel = true
        return
    end
    
    -- Reset game
    if key == "x" then
        resetGame()
    end
end

-- Path module lookup
local pathModules = {
    herbalism = Herbalism,
    crystal = Crystal,
    shores = Shores
}

-- Start gathering from specified path
function startGathering(pathName)
    if not ActionRunner.isIdle() then
        print("Action already in progress!")
        return
    end
    
    -- Check if path is available at current location
    if not World.isGatherPathAvailable(pathName) then
        local currentNode = World.getCurrentNode()
        print(string.format("Cannot gather %s at %s! (Press T to travel)", pathName, currentNode.name))
        return
    end
    
    local pathModule = pathModules[pathName]
    if not pathModule then
        print("Invalid path: " .. pathName)
        return
    end
    
    local gatherAction = pathModule.getGatherAction()
    local success, errorMsg = ActionRunner.startGather(gatherAction, StepSystem)
    
    if not success then
        print("Cannot start gathering: " .. (errorMsg or "Unknown error"))
    end
end

-- Start transform from specified path
function startTransform(pathName, transformType)
    if not ActionRunner.isIdle() then
        print("Action already in progress!")
        return
    end
    
    local pathModule = pathModules[pathName]
    if not pathModule then
        print("Invalid path: " .. pathName)
        return
    end
    
    local canTransform, errorMsg = pathModule.canTransform(transformType, Inventory)
    if not canTransform then
        print("Cannot transform: " .. errorMsg)
        return
    end
    
    local transform = pathModule.TRANSFORMS[transformType]
    local action = {
        name = transform.name,
        type = "transform",
        path = pathName,
        transformType = transformType,
        stepCost = transform.stepCost,
        duration = 2.0 -- 2 seconds for prototype
    }
    
    local success, errorMsg = ActionRunner.startSpend(action, StepSystem)
    if not success then
        print("Cannot start transform: " .. errorMsg)
    end
end

-- Start traveling to a destination
function startTravel(index)
    local connections = World.getConnections()
    
    if index < 1 or index > #connections then
        print("Invalid destination")
        return
    end
    
    local connection = connections[index]
    local targetNodeId = connection.node.id
    
    -- Travel (instant for prototype, could be action-based later)
    local success, message = World.travel(targetNodeId, StepSystem)
    
    if success then
        print(message)
        game.showTravel = false -- Close modal after traveling
    else
        print("Cannot travel: " .. message)
    end
end

-- Start crafting from menu
function startCrafting(index)
    if not ActionRunner.isIdle() then
        print("Action already in progress!")
        return
    end
    
    -- Get recipes for current category
    local recipes = game.craftingCategory == "consumables" and Crafting.CONSUMABLE_RECIPES or Crafting.EQUIPMENT_RECIPES
    
    -- Convert index to recipe ID
    local recipeId = nil
    local currentIndex = 1
    for id, recipe in pairs(recipes) do
        if currentIndex == index then
            recipeId = id
            break
        end
        currentIndex = currentIndex + 1
    end
    
    if not recipeId then
        print("Invalid recipe selection")
        return
    end
    
    -- Check if can craft
    local canCraft, errorMsg = Crafting.canCraft(recipeId, Inventory)
    if not canCraft then
        print("Cannot craft: " .. errorMsg)
        return
    end
    
    -- Get craft action
    local action = Crafting.getCraftAction(recipeId)
    if not action then
        print("Invalid craft action")
        return
    end
    
    -- Close crafting menu and start action
    game.showCrafting = false
    
    local success, errorMsg = ActionRunner.startSpend(action, StepSystem)
    if not success then
        print("Cannot start crafting: " .. errorMsg)
    end
end

-- Handle action completion
function handleActionComplete(completedAction)
    if not completedAction then
        return
    end
    
    if completedAction.type == "gather" then
        -- Add gather output to inventory
        for _, output in ipairs(completedAction.output) do
            Inventory.addItem(output.item, output.quantity)
            print(string.format("Gathered %d %s!", output.quantity, output.item))
            
            -- Update activity progress if there's an active activity
            if ActivityManager.getState() == "active" then
                ActivityManager.updateProgress(output.quantity, completedAction.stepCost)
            end
        end
        
        -- Record progression
        Progression.recordGather(completedAction.path, completedAction.stepCost)
        
        -- Check if activity is complete
        if ActivityManager.getState() == "active" and not ActivityManager.isActivityComplete() then
            -- Start next gather action
            local activity = ActivityManager.getCurrentActivity()
            if activity and activity.type == "gather" then
                local pathModule = pathModules[activity.path]
                if pathModule then
                    local gatherAction = pathModule.getGatherAction()
                    ActionRunner.startGather(gatherAction, StepSystem)
                end
            end
        else
            -- Activity complete or no activity, add remaining steps to bank
            local counts = StepSystem.getCounts()
            if counts.live > 0 then
                StepSystem.addToBank(counts.live)
                StepSystem.liveSteps = 0
            end
        end
        
    elseif completedAction.type == "transform" then
        -- Perform transform (steps already spent in ActionRunner)
        local pathModule = pathModules[completedAction.path]
        if pathModule then
            local success, message = pathModule.performTransform(
                completedAction.transformType, 
                Inventory, 
                StepSystem
            )
            
            if success then
                print(message)
                -- Record progression
                Progression.recordTransform(completedAction.path, completedAction.stepCost)
            else
                print("Transform failed: " .. (message or "Unknown error"))
                -- Refund steps if transform failed (shouldn't happen, but safety)
            end
        else
            print("Unknown path: " .. completedAction.path)
        end
        
    elseif completedAction.type == "craft" then
        -- Perform craft (steps already spent in ActionRunner)
        local success, message = Crafting.performCraft(
            completedAction.recipeId,
            Inventory,
            StepSystem
        )
        
        if success then
            print(message)
            
            -- Determine craft type (consumables or equipment)
            local recipe = Crafting.CONSUMABLE_RECIPES[completedAction.recipeId] or Crafting.EQUIPMENT_RECIPES[completedAction.recipeId]
            if recipe then
                local craftType = Crafting.CONSUMABLE_RECIPES[completedAction.recipeId] and "consumables" or "equipment"
                Progression.recordCraft(craftType, completedAction.stepCost)
            end
        else
            print("Craft failed: " .. (message or "Unknown error"))
        end
    end
end

-- Reset game
function resetGame()
    StepSystem.reset()
    Inventory.reset()
    ActionRunner.cancel()
    Equipment.reset()
    World.reset()
    Progression.reset()
    ActivityManager.reset()
    print("Game reset!")
end
