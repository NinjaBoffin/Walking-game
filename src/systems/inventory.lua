-- Inventory System Module
-- Handles 33-slot inventory with auto-merge and overflow handling

local Inventory = {}

Inventory.MAX_SLOTS = 33
Inventory.MAX_STACK_SIZE = 100
Inventory.slots = {}

-- Initialize inventory
function Inventory.init()
    Inventory.slots = {}
    print("Inventory initialized")
end

-- Add item to inventory (auto-merge stacks)
function Inventory.addItem(itemId, quantity)
    -- Try to merge with existing stack
    for i, slot in ipairs(Inventory.slots) do
        if slot.itemId == itemId and slot.quantity < Inventory.MAX_STACK_SIZE then
            local spaceAvailable = Inventory.MAX_STACK_SIZE - slot.quantity
            local toAdd = math.min(quantity, spaceAvailable)
            slot.quantity = slot.quantity + toAdd
            quantity = quantity - toAdd
            
            if quantity <= 0 then
                return true
            end
        end
    end
    
    -- Add to new slot if needed
    while quantity > 0 and #Inventory.slots < Inventory.MAX_SLOTS do
        local toAdd = math.min(quantity, Inventory.MAX_STACK_SIZE)
        table.insert(Inventory.slots, {
            itemId = itemId,
            quantity = toAdd
        })
        quantity = quantity - toAdd
    end
    
    -- Handle overflow
    if quantity > 0 then
        print(string.format("WARNING: Inventory overflow! %d %s could not be added", quantity, itemId))
        return false
    end
    
    return true
end

-- Remove item from inventory
function Inventory.removeItem(itemId, quantity)
    for i = #Inventory.slots, 1, -1 do
        local slot = Inventory.slots[i]
        if slot.itemId == itemId then
            if slot.quantity >= quantity then
                slot.quantity = slot.quantity - quantity
                if slot.quantity == 0 then
                    table.remove(Inventory.slots, i)
                end
                return true
            else
                quantity = quantity - slot.quantity
                table.remove(Inventory.slots, i)
            end
        end
    end
    
    return false
end

-- Get item count
function Inventory.getItemCount(itemId)
    local total = 0
    for _, slot in ipairs(Inventory.slots) do
        if slot.itemId == itemId then
            total = total + slot.quantity
        end
    end
    return total
end

-- Check if inventory has space
function Inventory.hasSpace()
    return #Inventory.slots < Inventory.MAX_SLOTS
end

-- Get inventory capacity info
function Inventory.getCapacityInfo()
    return {
        used = #Inventory.slots,
        max = Inventory.MAX_SLOTS,
        isFull = #Inventory.slots >= Inventory.MAX_SLOTS
    }
end

-- Check if over capacity (for step cost penalty)
function Inventory.isOverCapacity()
    return #Inventory.slots > Inventory.MAX_SLOTS
end

-- Get all items (for display)
function Inventory.getAllItems()
    local items = {}
    for _, slot in ipairs(Inventory.slots) do
        items[slot.itemId] = (items[slot.itemId] or 0) + slot.quantity
    end
    return items
end

-- Reset inventory
function Inventory.reset()
    Inventory.slots = {}
    print("Inventory reset")
end

return Inventory

