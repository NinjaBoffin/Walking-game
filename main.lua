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
    showCraftMenu = false, -- Combined crafting & transforms modal
    showTravel = false,
    showInventory = false,
    showEquipment = false, -- Equipment management modal
    craftMenuTab = "transforms", -- "transforms", "consumables", or "equipment"
    mouseX = 0,
    mouseY = 0,
    -- Craft/Transform progress tracking
    craftingInProgress = false,
    craftingName = "",
    craftingTimer = 0,
    craftingDuration = 10 -- 10 seconds for now
}

-- Path module lookup (needed by multiple functions)
local pathModules = {
    herbalism = Herbalism,
    crystal = Crystal,
    shores = Shores
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
    
    -- Update crafting timer
    if game.craftingInProgress then
        game.craftingTimer = game.craftingTimer + dt
        if game.craftingTimer >= game.craftingDuration then
            -- Crafting complete
            game.craftingInProgress = false
            game.craftingTimer = 0
        end
    end
    
    -- Simulate step accumulation ONLY when SPACE is held (for prototype)
    if love.keyboard.isDown("space") then
        StepSystem.updateSimulation(dt)
        
        -- Simulate live steps when gathering (only when SPACE is held)
        local actionInfo = ActionRunner.getCurrentAction()
        if actionInfo.action and actionInfo.state == "gather_active" then
            StepSystem.simulateLiveSteps(dt, 15) -- Faster rate for gathering simulation
        end
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
    if game.craftingInProgress then
        drawCraftingProgressModal()
    elseif game.showHelp then
        drawHelpModal()
    elseif game.showTravel then
        drawTravelModal()
    elseif game.showCraftMenu then
        drawCraftMenuModal()
    elseif game.showInventory then
        drawInventoryModal()
    elseif game.showEquipment then
        drawEquipmentModal()
    end
end

-- Draw active effects box (equipment + consumables)
function drawActiveEffects(x, y, width)
    local boxHeight = 20 -- Will expand based on content
    local contentY = y
    
    -- Check if there are any active effects
    local hasEffects = false
    for _, item in pairs(Equipment.equipped) do
        if item then hasEffects = true break end
    end
    if Equipment.activeConsumables.tea or Equipment.activeConsumables.potion then
        hasEffects = true
    end
    
    if not hasEffects then
        return y -- No effects to show
    end
    
    -- Draw box header
    love.graphics.setColor(0.2, 0.4, 0.6)
    love.graphics.rectangle("fill", x, y, width, 22)
    love.graphics.setColor(0.4, 0.6, 0.8)
    love.graphics.rectangle("line", x, y, width, 22)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Active Effects", x + 5, y + 5)
    contentY = contentY + 24
    
    -- Count effects to calculate height
    local effectCount = 0
    
    -- Show equipped items
    for slot, item in pairs(Equipment.equipped) do
        if item then
            effectCount = effectCount + 1
        end
    end
    
    -- Show active consumables
    if Equipment.activeConsumables.tea then effectCount = effectCount + 1 end
    if Equipment.activeConsumables.potion then effectCount = effectCount + 1 end
    
    local effectBoxHeight = effectCount * 20 + 10
    
    -- Draw content box
    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", x, contentY, width, effectBoxHeight)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", x, contentY, width, effectBoxHeight)
    
    contentY = contentY + 5
    
    -- List equipped items
    for slot, item in pairs(Equipment.equipped) do
        if item then
            love.graphics.setColor(0.9, 0.9, 0.5)
            love.graphics.print("• " .. item.itemId, x + 5, contentY)
            love.graphics.setColor(1, 1, 1)
            contentY = contentY + 20
        end
    end
    
    -- List active consumables
    if Equipment.activeConsumables.tea then
        local tea = Equipment.activeConsumables.tea
        love.graphics.setColor(0.7, 1, 0.7)
        love.graphics.print(string.format("• %s (%d steps)", tea.itemId, tea.stepsRemaining), x + 5, contentY)
        love.graphics.setColor(1, 1, 1)
        contentY = contentY + 20
    end
    
    if Equipment.activeConsumables.potion then
        local potion = Equipment.activeConsumables.potion
        love.graphics.setColor(0.7, 1, 0.7)
        love.graphics.print(string.format("• %s (%d uses)", potion.itemId, potion.usesRemaining), x + 5, contentY)
        love.graphics.setColor(1, 1, 1)
        contentY = contentY + 20
    end
    
    return contentY
end

-- Draw activity selection screen
function drawActivitySelectionScreen()
    Button.clear()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Header with inventory
    local headerHeight = 140
    drawBox(10, 10, screenW-20, headerHeight, "Walking RPG")
    local y = 42
    local counts = StepSystem.getCounts()
    love.graphics.print(string.format("Banked Steps: %.0f", counts.bank), 20, y)
    y = y + 20
    local currentNode = World.getCurrentNode()
    love.graphics.print(string.format("Location: %s (%s)", currentNode.name, currentNode.region), 20, y)
    y = y + 18
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print(currentNode.description, 20, y)
    love.graphics.setColor(1, 1, 1)
    
    -- Inventory summary
    y = y + 25
    local capacity = Inventory.getCapacityInfo()
    love.graphics.setColor(0.8, 1, 0.8)
    love.graphics.print(string.format("Inventory: %d/%d slots", capacity.used, capacity.max), 20, y)
    love.graphics.setColor(1, 1, 1)
    
    -- Show first few items
    local items = Inventory.getAllItems()
    local itemCount = 0
    local itemText = ""
    for itemName, quantity in pairs(items) do
        if itemCount < 5 then
            itemText = itemText .. itemName .. " x" .. quantity .. "  "
            itemCount = itemCount + 1
        end
    end
    if itemCount > 0 then
        y = y + 18
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print(itemText, 30, y)
        if capacity.used > 5 then
            love.graphics.print("...", 30 + love.graphics.getFont():getWidth(itemText), y)
        end
        love.graphics.setColor(1, 1, 1)
    end
    
    -- Active effects display
    drawActiveEffects(screenW - 310, 10, 300)
    
    -- Activity selection area
    y = headerHeight + 20
    drawBox(10, y, screenW-20, screenH-y-60, "Select Activity")
    y = y + 35
    
    local activities = ActivityManager.getAvailableActivities(World)
    local buttonY = y
    local buttonX = 30
    local buttonWidth = screenW - 60
    local buttonHeight = 60
    
    -- Gathering activities
    love.graphics.setColor(0.8, 0.9, 1)
    love.graphics.print("GATHERING", buttonX, buttonY)
    love.graphics.setColor(1, 1, 1)
    buttonY = buttonY + 25
    
    for i, activity in ipairs(activities) do
        -- Create button
        local btn = Button.create(
            activity.id,
            buttonX,
            buttonY,
            buttonWidth,
            buttonHeight,
            activity.data.name,
            function()
                ActivityManager.startConfiguration(activity.id)
            end
        )
        Button.register(btn)
        Button.draw(btn)
        
        -- Show step cost
        if activity.data.stepsPerItem then
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print(string.format("%d steps per item", activity.data.stepsPerItem), buttonX + 10, buttonY + 35)
            love.graphics.setColor(1, 1, 1)
        end
        
        buttonY = buttonY + buttonHeight + 10
    end
    
    -- Quick action buttons at bottom (2 rows for better fit)
    buttonY = screenH - 130
    local quickButtonWidth = (screenW - 60) / 2 - 10  -- 2 columns instead of 4
    
    -- Row 1: Craft/Transform and Inventory
    local btnCraft = Button.create(
        "craft",
        buttonX,
        buttonY,
        quickButtonWidth,
        50,
        "Craft/Transform",
        function() 
            game.showCraftMenu = true
            game.craftMenuTab = "transforms"
        end
    )
    Button.register(btnCraft)
    Button.draw(btnCraft)
    
    local btnInventory = Button.create(
        "inventory",
        buttonX + quickButtonWidth + 15,
        buttonY,
        quickButtonWidth,
        50,
        "Inventory",
        function() game.showInventory = true end
    )
    Button.register(btnInventory)
    Button.draw(btnInventory)
    
    -- Row 2: Equipment and Travel
    buttonY = buttonY + 60
    local btnEquipment = Button.create(
        "equipment",
        buttonX,
        buttonY,
        quickButtonWidth,
        50,
        "Equipment",
        function() game.showEquipment = true end
    )
    Button.register(btnEquipment)
    Button.draw(btnEquipment)
    
    local btnTravel = Button.create(
        "travel",
        buttonX + quickButtonWidth + 15,
        buttonY,
        quickButtonWidth,
        50,
        "Travel",
        function() game.showTravel = true end
    )
    Button.register(btnTravel)
    Button.draw(btnTravel)
    
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
                        ActionRunner.startGather(gatherAction, StepSystem, Equipment)
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
    drawBox(10, 10, screenW-20, 120, "Active Activity")
    local y = 42
    love.graphics.setColor(0.8, 1, 0.8)
    love.graphics.print(activity.name, 20, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 25
    
    local counts = StepSystem.getCounts()
    love.graphics.print(string.format("Banked Steps: %.0f  |  Live Steps: %.0f", counts.bank, counts.live), 20, y)
    y = y + 20
    
    -- Important instruction
    love.graphics.setColor(1, 1, 0.8)
    love.graphics.print("⚠ HOLD SPACEBAR to walk and accumulate steps!", 20, y)
    love.graphics.setColor(1, 1, 1)
    
    -- Active effects display
    drawActiveEffects(screenW - 310, 10, 300)
    
    -- Progress area
    y = 150
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
    
    -- Inventory display
    y = 420
    drawBox(10, y, screenW-20, 100, "Inventory")
    y = y + 35
    
    local items = Inventory.getAllItems()
    local capacity = Inventory.getCapacityInfo()
    love.graphics.print(string.format("Slots: %d/%d", capacity.used, capacity.max), 30, y)
    y = y + 20
    
    local itemCount = 0
    for itemName, quantity in pairs(items) do
        if itemCount < 8 then
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print(string.format("%s x%d", itemName, quantity), 30 + (itemCount % 4) * 200, y + math.floor(itemCount / 4) * 18)
            love.graphics.setColor(1, 1, 1)
            itemCount = itemCount + 1
        end
    end
    
    -- Current action status
    y = 540
    drawBox(10, y, screenW-20, 80, "Current Action")
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

-- Draw travel modal with visual node-based map
function drawTravelModal()
    Button.clear()
    local modalW = 700
    local modalH = 550
    local modalX = (love.graphics.getWidth() - modalW) / 2
    local modalY = (love.graphics.getHeight() - modalH) / 2
    
    drawModal(modalX, modalY, modalW, modalH, "Travel Map")
    
    -- Map area
    local mapX = modalX + 20
    local mapY = modalY + 50
    local mapW = modalW - 40
    local mapH = 450
    
    -- Draw map background
    love.graphics.setColor(0.15, 0.15, 0.2)
    love.graphics.rectangle("fill", mapX, mapY, mapW, mapH)
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.rectangle("line", mapX, mapY, mapW, mapH)
    
    local currentNodeId = World.currentLocation
    local counts = StepSystem.getCounts()
    
    -- First pass: Draw connection lines
    for nodeId, node in pairs(World.NODES) do
        if node.mapPos and node.connections then
            local x1 = mapX + node.mapPos.x
            local y1 = mapY + node.mapPos.y
            
            for _, conn in ipairs(node.connections) do
                local targetNode = World.NODES[conn.to]
                if targetNode and targetNode.mapPos then
                    local x2 = mapX + targetNode.mapPos.x
                    local y2 = mapY + targetNode.mapPos.y
                    
                    -- Draw connection line
                    love.graphics.setColor(0.3, 0.3, 0.4)
                    love.graphics.setLineWidth(2)
                    love.graphics.line(x1, y1, x2, y2)
                    
                    -- Draw cost label at midpoint
                    local midX = (x1 + x2) / 2
                    local midY = (y1 + y2) / 2
                    love.graphics.setColor(0.6, 0.6, 0.7)
                    love.graphics.print(tostring(conn.cost), midX - 15, midY - 8)
                end
            end
        end
    end
    
    -- Second pass: Draw nodes
    for nodeId, node in pairs(World.NODES) do
        if node.mapPos then
            local nodeX = mapX + node.mapPos.x
            local nodeY = mapY + node.mapPos.y
            local nodeRadius = 25
            local isCurrent = (nodeId == currentNodeId)
            local isConnected = false
            
            -- Check if this node is connected to current location
            local currentNode = World.NODES[currentNodeId]
            if currentNode and currentNode.connections then
                for _, conn in ipairs(currentNode.connections) do
                    if conn.to == nodeId then
                        isConnected = true
                        break
                    end
                end
            end
            
            -- Node circle
            if isCurrent then
                -- Current location - bright green
                love.graphics.setColor(0.3, 0.8, 0.3)
                love.graphics.circle("fill", nodeX, nodeY, nodeRadius + 3)
                love.graphics.setColor(0.5, 1, 0.5)
                love.graphics.circle("fill", nodeX, nodeY, nodeRadius)
            elseif isConnected then
                -- Can travel here - check if affordable
                local cost = 0
                for _, conn in ipairs(currentNode.connections) do
                    if conn.to == nodeId then
                        cost = conn.cost
                        break
                    end
                end
                
                local canAfford = counts.bank >= cost
                if canAfford then
                    love.graphics.setColor(0.4, 0.6, 0.8)
                else
                    love.graphics.setColor(0.6, 0.3, 0.3)
                end
                love.graphics.circle("fill", nodeX, nodeY, nodeRadius)
                
                -- Make it clickable
                local btn = Button.create(
                    "travel_" .. nodeId,
                    nodeX - nodeRadius,
                    nodeY - nodeRadius,
                    nodeRadius * 2,
                    nodeRadius * 2,
                    "",
                    function()
                        if canAfford then
                            World.travel(nodeId, StepSystem)
                            game.showTravel = false
                        else
                            print(string.format("Need %d steps, have %.0f", cost, counts.bank))
                        end
                    end
                )
                Button.register(btn)
            else
                -- Not connected - gray
                love.graphics.setColor(0.3, 0.3, 0.3)
                love.graphics.circle("fill", nodeX, nodeY, nodeRadius)
            end
            
            -- Node border
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", nodeX, nodeY, nodeRadius)
            
            -- Node name
            love.graphics.setColor(1, 1, 1)
            local nameWidth = love.graphics.getFont():getWidth(node.name)
            love.graphics.print(node.name, nodeX - nameWidth/2, nodeY + nodeRadius + 5)
            
            -- Gather paths icons
            if #node.gatherPaths > 0 then
                love.graphics.setColor(0.7, 0.9, 1)
                local pathText = table.concat(node.gatherPaths, ","):sub(1, 1):upper()
                love.graphics.print(pathText, nodeX - 3, nodeY - 6)
            end
        end
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(1)
    
    -- Instructions at bottom
    local y = modalY + modalH - 25
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Click a connected node to travel  |  Esc - Close", modalX + 20, y)
    love.graphics.setColor(1, 1, 1)
end

-- Draw inventory modal
-- Draw crafting progress modal
function drawCraftingProgressModal()
    local modalW = 500
    local modalH = 250
    local modalX = (love.graphics.getWidth() - modalW) / 2
    local modalY = (love.graphics.getHeight() - modalH) / 2
    
    drawModal(modalX, modalY, modalW, modalH, "Crafting in Progress")
    
    local y = modalY + 50
    local x = modalX + 20
    
    -- Crafting item name
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(game.craftingName, x, y, modalW - 40, "center")
    y = y + 40
    
    -- Progress bar
    local progress = game.craftingTimer / game.craftingDuration
    local barWidth = modalW - 80
    local barHeight = 30
    local barX = modalX + 40
    
    -- Background
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", barX, y, barWidth, barHeight)
    
    -- Progress fill
    love.graphics.setColor(0.4, 0.7, 0.4)
    love.graphics.rectangle("fill", barX, y, barWidth * progress, barHeight)
    
    -- Border
    love.graphics.setColor(0.5, 0.7, 0.9)
    love.graphics.rectangle("line", barX, y, barWidth, barHeight)
    
    y = y + 50
    
    -- Timer text
    love.graphics.setColor(0.8, 0.9, 1)
    local timeRemaining = math.max(0, game.craftingDuration - game.craftingTimer)
    love.graphics.printf(
        string.format("Time remaining: %.1fs", timeRemaining),
        x,
        y,
        modalW - 40,
        "center"
    )
    
    y = y + 30
    
    -- Instruction
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf(
        "Set it and forget it! Come back when it's done.",
        x,
        y,
        modalW - 40,
        "center"
    )
    
    love.graphics.setColor(1, 1, 1)
end

-- Helper function to identify item type
function getItemType(itemName)
    -- Check if it's a consumable
    for recipeId, recipe in pairs(Crafting.CONSUMABLE_RECIPES) do
        if recipe.output.item == itemName then
            return "consumable", recipe
        end
    end
    
    -- Check if it's equipment
    for recipeId, recipe in pairs(Crafting.EQUIPMENT_RECIPES) do
        if recipe.output.item == itemName then
            return "equipment", recipe
        end
    end
    
    return "material", nil
end

function drawInventoryModal()
    Button.clear()
    local modalW = 700
    local modalH = 550
    local modalX = (love.graphics.getWidth() - modalW) / 2
    local modalY = (love.graphics.getHeight() - modalH) / 2
    
    drawModal(modalX, modalY, modalW, modalH, "Inventory")
    
    local y = modalY + 45
    local x = modalX + 15
    
    local capacity = Inventory.getCapacityInfo()
    love.graphics.setColor(0.8, 0.9, 1)
    love.graphics.print(string.format("Slots Used: %d / %d", capacity.used, capacity.max), x, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 35
    
    local items = Inventory.getAllItems()
    local itemCount = 0
    
    if capacity.used == 0 then
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("Your inventory is empty. Start gathering to collect items!", x, y)
        love.graphics.setColor(1, 1, 1)
    else
        for itemName, quantity in pairs(items) do
            -- Item box
            local boxH = 60
            local col = itemCount % 2
            local row = math.floor(itemCount / 2)
            local boxX = x + col * 330
            local boxY = y + row * 70
            
            love.graphics.setColor(0.25, 0.25, 0.25)
            love.graphics.rectangle("fill", boxX, boxY, 320, boxH)
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.rectangle("line", boxX, boxY, 320, boxH)
            
            -- Item name and quantity
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(itemName, boxX+10, boxY+8)
            love.graphics.setColor(0.8, 1, 0.8)
            love.graphics.print(string.format("x%d", quantity), boxX+10, boxY+26)
            love.graphics.setColor(1, 1, 1)
            
            -- Check if this is a usable item
            local itemType, recipe = getItemType(itemName)
            if itemType == "consumable" then
                -- Add "Use" button for consumables
                local btnUse = Button.create(
                    "use_" .. itemName,
                    boxX + 200,
                    boxY + 20,
                    100,
                    30,
                    "Use",
                    function() 
                        useConsumable(itemName, recipe)
                    end
                )
                Button.register(btnUse)
                Button.draw(btnUse)
            elseif itemType == "equipment" then
                -- Add "Equip" button for equipment
                local btnEquip = Button.create(
                    "equip_" .. itemName,
                    boxX + 200,
                    boxY + 20,
                    100,
                    30,
                    "Equip",
                    function()
                        equipItem(itemName, recipe)
                    end
                )
                Button.register(btnEquip)
                Button.draw(btnEquip)
            end
            
            itemCount = itemCount + 1
        end
    end
    
    -- Instructions at bottom
    y = modalY + modalH - 30
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Esc - Close  |  Click Use/Equip buttons to use items", x, y)
    love.graphics.setColor(1, 1, 1)
end

-- Use a consumable item
function useConsumable(itemName, recipe)
    -- Remove item from inventory
    local success = Inventory.removeItem(itemName, 1)
    if not success then
        print("Failed to remove item from inventory")
        return
    end
    
    -- Activate consumable based on type
    if recipe.type == "tea" then
        Equipment.activateConsumable("tea", itemName, recipe.effect)
        print(string.format("Activated %s! %s", recipe.name, recipe.description))
    elseif recipe.type == "potion" then
        Equipment.activateConsumable("potion", itemName, recipe.effect)
        print(string.format("Activated %s! %s", recipe.name, recipe.description))
    elseif recipe.type == "snack" then
        Equipment.useSnack(recipe.effect, StepSystem)
        print(string.format("Used %s! %s", recipe.name, recipe.description))
    end
end

-- Equip an equipment item
function equipItem(itemName, recipe)
    -- Get the slot type for this equipment
    local slot = recipe.type -- "pendant", "bracelet", or "wrap"
    
    -- Check if slot already has equipment
    local currentEquip = Equipment.equipped[slot]
    if currentEquip then
        -- Return old equipment to inventory
        local returnSuccess = Inventory.addItem(currentEquip.itemId, 1)
        if not returnSuccess then
            print("Inventory full! Cannot unequip current item.")
            return
        end
    end
    
    -- Remove new equipment from inventory
    local success = Inventory.removeItem(itemName, 1)
    if not success then
        print("Failed to remove item from inventory")
        return
    end
    
    -- Equip the item
    Equipment.equip(slot, itemName, recipe.effect)
    print(string.format("Equipped %s to %s slot!", recipe.name, slot))
end

-- Draw equipment modal
function drawEquipmentModal()
    Button.clear()
    local modalW = 600
    local modalH = 500
    local modalX = (love.graphics.getWidth() - modalW) / 2
    local modalY = (love.graphics.getHeight() - modalH) / 2
    
    drawModal(modalX, modalY, modalW, modalH, "Equipment & Effects")
    
    local y = modalY + 45
    local x = modalX + 15
    
    -- Equipment slots section
    love.graphics.setColor(0.8, 0.9, 1)
    love.graphics.print("EQUIPMENT SLOTS", x, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 30
    
    local slots = {"pendant", "bracelet", "wrap"}
    local slotNames = {pendant = "Pendant", bracelet = "Bracelet", wrap = "Wrap"}
    
    for _, slot in ipairs(slots) do
        -- Slot box
        local boxH = 70
        love.graphics.setColor(0.25, 0.25, 0.25)
        love.graphics.rectangle("fill", x, y, modalW - 30, boxH)
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle("line", x, y, modalW - 30, boxH)
        
        -- Slot name
        love.graphics.setColor(0.9, 0.9, 0.5)
        love.graphics.print(slotNames[slot] .. ":", x + 10, y + 10)
        love.graphics.setColor(1, 1, 1)
        
        local equippedItem = Equipment.equipped[slot]
        if equippedItem then
            -- Show equipped item
            love.graphics.print(equippedItem.itemId, x + 10, y + 30)
            
            -- Show effect description
            love.graphics.setColor(0.7, 1, 0.7)
            local effectDesc = ""
            if equippedItem.effect.type == "reduce_cost" then
                effectDesc = string.format("-%d%% %s cost", 
                    equippedItem.effect.amount * 100, 
                    equippedItem.effect.target:gsub("_", " "))
            elseif equippedItem.effect.type == "bonus_chance" then
                effectDesc = string.format("+%d%% bonus %s", 
                    equippedItem.effect.amount * 100, 
                    equippedItem.effect.target:gsub("_", " "))
            end
            love.graphics.print(effectDesc, x + 10, y + 48)
            love.graphics.setColor(1, 1, 1)
            
            -- Unequip button
            local btnUnequip = Button.create(
                "unequip_" .. slot,
                x + modalW - 150,
                y + 20,
                100,
                30,
                "Unequip",
                function()
                    local item = Equipment.equipped[slot]
                    if item then
                        -- Return to inventory
                        local success = Inventory.addItem(item.itemId, 1)
                        if success then
                            Equipment.unequip(slot)
                            print("Unequipped " .. item.itemId)
                        else
                            print("Inventory full!")
                        end
                    end
                end
            )
            Button.register(btnUnequip)
            Button.draw(btnUnequip)
        else
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.print("(empty)", x + 10, y + 30)
            love.graphics.setColor(1, 1, 1)
        end
        
        y = y + boxH + 10
    end
    
    y = y + 10
    
    -- Active consumables section
    love.graphics.setColor(0.8, 0.9, 1)
    love.graphics.print("ACTIVE CONSUMABLES", x, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 30
    
    -- Tea slot
    local boxH = 60
    love.graphics.setColor(0.25, 0.25, 0.25)
    love.graphics.rectangle("fill", x, y, modalW - 30, boxH)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", x, y, modalW - 30, boxH)
    
    love.graphics.setColor(0.9, 0.9, 0.5)
    love.graphics.print("Tea:", x + 10, y + 10)
    love.graphics.setColor(1, 1, 1)
    
    if Equipment.activeConsumables.tea then
        local tea = Equipment.activeConsumables.tea
        love.graphics.print(tea.itemId, x + 10, y + 30)
        love.graphics.setColor(0.7, 1, 0.7)
        love.graphics.print(string.format("%d steps remaining", tea.stepsRemaining), x + 250, y + 30)
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("(no active tea)", x + 10, y + 30)
        love.graphics.setColor(1, 1, 1)
    end
    
    y = y + boxH + 10
    
    -- Potion slot
    love.graphics.setColor(0.25, 0.25, 0.25)
    love.graphics.rectangle("fill", x, y, modalW - 30, boxH)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", x, y, modalW - 30, boxH)
    
    love.graphics.setColor(0.9, 0.9, 0.5)
    love.graphics.print("Potion:", x + 10, y + 10)
    love.graphics.setColor(1, 1, 1)
    
    if Equipment.activeConsumables.potion then
        local potion = Equipment.activeConsumables.potion
        love.graphics.print(potion.itemId, x + 10, y + 30)
        love.graphics.setColor(0.7, 1, 0.7)
        love.graphics.print(string.format("%d uses remaining", potion.usesRemaining), x + 250, y + 30)
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("(no active potion)", x + 10, y + 30)
        love.graphics.setColor(1, 1, 1)
    end
    
    -- Instructions at bottom
    y = modalY + modalH - 30
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Esc - Close  |  Use consumables from Inventory", x, y)
    love.graphics.setColor(1, 1, 1)
end

-- Draw combined craft menu modal (transforms + crafting)
function drawCraftMenuModal()
    local modalW = 700
    local modalH = 550
    local modalX = (love.graphics.getWidth() - modalW) / 2
    local modalY = (love.graphics.getHeight() - modalH) / 2
    
    local tabName = game.craftMenuTab == "transforms" and "TRANSFORMS" or 
                    game.craftMenuTab == "consumables" and "CONSUMABLES" or "EQUIPMENT"
    drawModal(modalX, modalY, modalW, modalH, "Craft Menu - " .. tabName)
    
    local y = modalY + 45
    local x = modalX + 15
    
    -- Tab buttons (clickable)
    local tabWidth = 200
    local tabHeight = 30
    local tabX = modalX + (modalW - tabWidth * 3) / 2
    
    -- Transforms tab button
    local btnTransforms = Button.create(
        "tab_transforms",
        tabX,
        y,
        tabWidth,
        tabHeight,
        "Transforms",
        function() game.craftMenuTab = "transforms" end
    )
    btnTransforms.isActive = (game.craftMenuTab == "transforms")
    Button.register(btnTransforms)
    Button.draw(btnTransforms)
    
    -- Consumables tab button
    local btnConsumables = Button.create(
        "tab_consumables",
        tabX + tabWidth,
        y,
        tabWidth,
        tabHeight,
        "Consumables",
        function() game.craftMenuTab = "consumables" end
    )
    btnConsumables.isActive = (game.craftMenuTab == "consumables")
    Button.register(btnConsumables)
    Button.draw(btnConsumables)
    
    -- Equipment tab button
    local btnEquipment = Button.create(
        "tab_equipment",
        tabX + tabWidth * 2,
        y,
        tabWidth,
        tabHeight,
        "Equipment",
        function() game.craftMenuTab = "equipment" end
    )
    btnEquipment.isActive = (game.craftMenuTab == "equipment")
    Button.register(btnEquipment)
    Button.draw(btnEquipment)
    
    y = y + 50
    
    -- Content based on selected tab
    if game.craftMenuTab == "transforms" then
        drawTransformsContent(x, y, modalW)
    elseif game.craftMenuTab == "consumables" then
        drawCraftingContent(x, y, modalW, "consumables")
    else
        drawCraftingContent(x, y, modalW, "equipment")
    end
    
    -- Instructions at bottom
    y = modalY + modalH - 30
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Click tabs to switch  |  Click recipes to craft/transform  |  C/Esc - Close", x, y)
    love.graphics.setColor(1, 1, 1)
end

-- Draw transforms content
function drawTransformsContent(x, y, modalW)
    love.graphics.setColor(0.8, 0.9, 1)
    love.graphics.print("Click a transform to perform instantly (uses banked steps)", x, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 35
    
    local transforms = ActivityManager.getTransformActivities()
    
    for i, transform in ipairs(transforms) do
        local boxY = y
        local boxH = 60
        
        -- Create clickable button for entire transform box
        local btnTransform = Button.create(
            "transform_" .. i,
            x,
            boxY,
            modalW - 30,
            boxH,
            "", -- No text, we'll draw custom content
            function() startTransformFromModal(i) end
        )
        Button.register(btnTransform)
        
        -- Custom drawing for transform box
        if btnTransform.hovered then
            love.graphics.setColor(0.3, 0.3, 0.35)
        else
            love.graphics.setColor(0.25, 0.25, 0.25)
        end
        love.graphics.rectangle("fill", x, boxY, modalW-30, boxH)
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle("line", x, boxY, modalW-30, boxH)
        
        -- Transform name
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(transform.data.name, x+10, boxY+5)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print(string.format("(%d steps)", transform.data.stepCost), x+200, boxY+5)
        
        -- Transform details
        love.graphics.setColor(0.8, 0.9, 1)
        local detailText = ""
        if transform.id == "transform_dry" then
            detailText = "2 herb → 1 dried_herb"
        elseif transform.id == "transform_press_herb" then
            detailText = "3 herb → 1 pressed_flower"
        elseif transform.id == "transform_polish" then
            detailText = "2 crystal_shard → 1 polished_crystal"
        elseif transform.id == "transform_tumble" then
            detailText = "3 crystal_shard → 1 tumbled_stone"
        elseif transform.id == "transform_salt" then
            detailText = "2 shell → 1 sea_salt"
        elseif transform.id == "transform_press_kelp" then
            detailText = "3 shell → 1 kelp_flakes"
        end
        love.graphics.print(detailText, x+10, boxY+30)
        love.graphics.setColor(1, 1, 1)
        
        y = y + boxH + 10
    end
end

-- Draw crafting content
function drawCraftingContent(x, y, modalW, category)
    love.graphics.setColor(0.8, 0.9, 1)
    love.graphics.print("Click a recipe to craft (uses banked steps + materials)", x, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 35
    
    -- Get ordered list of recipes
    local orderedRecipes = getOrderedRecipes(category)
    
    for index, recipeData in ipairs(orderedRecipes) do
        local recipe = recipeData.recipe
        
        -- Check if player has materials
        local canCraft, missingItems = Crafting.canCraft(recipeData.id, Inventory)
        
        local boxY = y
        local boxH = 80
        
        -- Create clickable button for entire recipe box
        local btnRecipe = Button.create(
            "recipe_" .. index,
            x,
            boxY,
            modalW - 30,
            boxH,
            "", -- No text, we'll draw custom content
            function() startCraftingFromModal(index) end
        )
        btnRecipe.enabled = canCraft
        Button.register(btnRecipe)
        
        -- Custom drawing for recipe box
        if not canCraft then
            love.graphics.setColor(0.15, 0.15, 0.15)
        elseif btnRecipe.hovered then
            love.graphics.setColor(0.3, 0.35, 0.3)
        else
            love.graphics.setColor(0.25, 0.25, 0.25)
        end
        love.graphics.rectangle("fill", x, boxY, modalW-30, boxH)
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle("line", x, boxY, modalW-30, boxH)
        
        -- Recipe name
        if canCraft then
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0.6, 0.6, 0.6)
        end
        love.graphics.print(recipe.name, x+10, boxY+5)
        
        -- Availability status
        if not canCraft then
            love.graphics.setColor(1, 0.5, 0.5)
            love.graphics.print("[LOCKED]", x+200, boxY+5)
        else
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print(string.format("(%d steps)", recipe.stepCost), x+200, boxY+5)
        end
        
        -- Materials (show what you have vs what you need)
        for i, mat in ipairs(recipe.inputs) do
            local hasQty = Inventory.getItemCount(mat.item)
            if hasQty >= mat.quantity then
                love.graphics.setColor(0.6, 1, 0.6) -- Green if you have enough
            else
                love.graphics.setColor(1, 0.6, 0.6) -- Red if not enough
            end
            love.graphics.print(string.format("%d/%d %s", hasQty, mat.quantity, mat.item), x+10 + (i-1)*200, boxY+30)
        end
        
        -- Effect
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print(recipe.description, x+10, boxY+55)
        love.graphics.setColor(1, 1, 1)
        
        y = y + boxH + 10
        
        if index >= 6 then break end -- Limit display
    end
end

-- Get ordered list of recipes for a category
function getOrderedRecipes(category)
    local recipes = category == "consumables" and Crafting.CONSUMABLE_RECIPES or Crafting.EQUIPMENT_RECIPES
    local ordered = {}
    
    -- Define order for consumables
    if category == "consumables" then
        local order = {"tea_herbalism", "potion_craft_queue", "snack_step_refund"}
        for _, id in ipairs(order) do
            if recipes[id] then
                table.insert(ordered, {id = id, recipe = recipes[id]})
            end
        end
    else
        -- Define order for equipment
        local order = {"pendant_craft_reduction", "bracelet_herbalism_bonus", "wrap_polish_reduction"}
        for _, id in ipairs(order) do
            if recipes[id] then
                table.insert(ordered, {id = id, recipe = recipes[id]})
            end
        end
    end
    
    return ordered
end

-- Old transforms modal (keeping for reference, will remove)
function drawTransformsModal_OLD()
    local modalW = 700
    local modalH = 550
    local modalX = (love.graphics.getWidth() - modalW) / 2
    local modalY = (love.graphics.getHeight() - modalH) / 2
    
    drawModal(modalX, modalY, modalW, modalH, "Transforms")
    
    local y = modalY + 45
    local x = modalX + 15
    
    love.graphics.setColor(0.8, 0.9, 1)
    love.graphics.print("Select a transform to perform instantly (uses banked steps)", x, y)
    love.graphics.setColor(1, 1, 1)
    y = y + 35
    
    local transforms = ActivityManager.getTransformActivities()
    
    for i, transform in ipairs(transforms) do
        -- Transform box
        local boxY = y
        local boxH = 60
        love.graphics.setColor(0.25, 0.25, 0.25)
        love.graphics.rectangle("fill", x, boxY, modalW-30, boxH)
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle("line", x, boxY, modalW-30, boxH)
        
        -- Transform name and key
        love.graphics.setColor(0.8, 1, 0.8)
        love.graphics.print(string.format("[%d]", i), x+5, boxY+5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(transform.data.name, x+30, boxY+5)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print(string.format("(%d steps)", transform.data.stepCost), x+200, boxY+5)
        
        -- Transform details (would need to add to activity data)
        love.graphics.setColor(0.8, 0.9, 1)
        local detailText = ""
        if transform.id == "transform_dry" then
            detailText = "2 herb → 1 dried_herb"
        elseif transform.id == "transform_press_herb" then
            detailText = "3 herb → 1 pressed_flower"
        elseif transform.id == "transform_polish" then
            detailText = "2 crystal_shard → 1 polished_crystal"
        elseif transform.id == "transform_tumble" then
            detailText = "3 crystal_shard → 1 tumbled_stone"
        elseif transform.id == "transform_salt" then
            detailText = "2 shell → 1 sea_salt"
        elseif transform.id == "transform_press_kelp" then
            detailText = "3 shell → 1 kelp_flakes"
        end
        love.graphics.print(detailText, x+10, boxY+30)
        love.graphics.setColor(1, 1, 1)
        
        y = y + boxH + 10
    end
    
    -- Instructions at bottom
    y = modalY + modalH - 30
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("1-6 - Perform Transform  |  Esc - Close", x, y)
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
    
    if game.showCraftMenu then
        if key == "tab" then
            -- Cycle through tabs: transforms -> consumables -> equipment -> transforms
            if game.craftMenuTab == "transforms" then
                game.craftMenuTab = "consumables"
            elseif game.craftMenuTab == "consumables" then
                game.craftMenuTab = "equipment"
            else
                game.craftMenuTab = "transforms"
            end
        elseif key == "escape" or key == "c" then
            game.showCraftMenu = false
        end
        return
    end
    
    if game.showInventory then
        if key == "escape" or key == "i" then
            game.showInventory = false
        end
        return
    end
    
    if game.showEquipment then
        if key == "escape" or key == "e" then
            game.showEquipment = false
        end
        return
    end
    
    -- Toggle help
    if key == "h" then
        game.showHelp = true
        return
    end
    
    -- Toggle equipment (only from activity selection screen)
    if key == "e" and ActivityManager.getState() == "selection" then
        game.showEquipment = true
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

-- Start transform from modal (by index)
function startTransformFromModal(index)
    local transforms = ActivityManager.getTransformActivities()
    if index < 1 or index > #transforms then
        print("Invalid transform selection")
        return
    end
    
    local transform = transforms[index]
    startTransform(transform.data.path, transform.data.transformType)
    game.showCraftMenu = false
end

-- Start crafting from modal (by index)
function startCraftingFromModal(index)
    local category = game.craftMenuTab == "consumables" and "consumables" or "equipment"
    local orderedRecipes = getOrderedRecipes(category)
    
    if index < 1 or index > #orderedRecipes then
        print("Invalid recipe selection")
        return
    end
    
    local recipeData = orderedRecipes[index]
    
    -- Check if player has materials
    local canCraft, missingItems = Crafting.canCraft(recipeData.id, Inventory)
    if not canCraft then
        print("Cannot craft " .. recipeData.recipe.name .. " - missing materials!")
        return
    end
    
    startCrafting(recipeData.id)
    game.showCraftMenu = false
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
    
    -- Start crafting progress modal
    game.craftingInProgress = true
    game.craftingName = "Transforming: " .. transform.name
    game.craftingTimer = 0
    
    -- Schedule the actual transform to happen after the timer
    -- For now, we'll do it immediately but show the progress
    local success, errorMsg = ActionRunner.startSpend(action, StepSystem, Equipment, "transform")
    if not success then
        print("Cannot start transform: " .. errorMsg)
        game.craftingInProgress = false
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
function startCrafting(recipeId)
    if not ActionRunner.isIdle() then
        print("Action already in progress!")
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
    
    -- Start crafting progress modal
    game.craftingInProgress = true
    game.craftingName = "Crafting: " .. action.name
    game.craftingTimer = 0
    
    -- Schedule the actual craft to happen after the timer
    -- Determine action type based on recipe category
    local actionType = "consumable_craft"
    if Crafting.EQUIPMENT_RECIPES[recipeId] then
        actionType = "equipment_craft"
    end
    
    local success, errorMsg = ActionRunner.startSpend(action, StepSystem, Equipment, actionType)
    if not success then
        print("Cannot start crafting: " .. errorMsg)
        game.craftingInProgress = false
    end
end

-- Handle action completion
function handleActionComplete(completedAction)
    if not completedAction then
        return
    end
    
    if completedAction.type == "gather" then
        -- Update consumables (tea duration)
        Equipment.updateConsumables(completedAction.stepCost)
        
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
        -- Update potion uses
        Equipment.decrementPotionUses()
        
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
