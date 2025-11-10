-- Button UI Module
-- Handles button rendering and mouse interaction

local Button = {}

-- Button state
Button.buttons = {}
Button.hoveredButton = nil

-- Create a button
function Button.create(id, x, y, width, height, text, callback)
    return {
        id = id,
        x = x,
        y = y,
        width = width,
        height = height,
        text = text,
        callback = callback,
        hovered = false,
        enabled = true
    }
end

-- Register a button
function Button.register(button)
    Button.buttons[button.id] = button
end

-- Clear all buttons
function Button.clear()
    Button.buttons = {}
    Button.hoveredButton = nil
end

-- Check if mouse is over a button
function Button.isMouseOver(button, mx, my)
    return mx >= button.x and mx <= button.x + button.width and
           my >= button.y and my <= button.y + button.height
end

-- Update button hover states
function Button.updateHover(mx, my)
    Button.hoveredButton = nil
    for id, button in pairs(Button.buttons) do
        if button.enabled and Button.isMouseOver(button, mx, my) then
            button.hovered = true
            Button.hoveredButton = id
        else
            button.hovered = false
        end
    end
end

-- Handle mouse click
function Button.handleClick(mx, my)
    for id, button in pairs(Button.buttons) do
        if button.enabled and Button.isMouseOver(button, mx, my) then
            if button.callback then
                button.callback()
            end
            return true
        end
    end
    return false
end

-- Draw a button
function Button.draw(button)
    if not button.enabled then
        love.graphics.setColor(0.2, 0.2, 0.2)
    elseif button.isActive then
        -- Active state (for tabs)
        love.graphics.setColor(0.4, 0.6, 0.8)
    elseif button.hovered then
        love.graphics.setColor(0.4, 0.6, 0.8)
    else
        love.graphics.setColor(0.3, 0.5, 0.7)
    end
    
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
    
    -- Border (thicker for active tabs)
    if button.isActive then
        love.graphics.setLineWidth(3)
        love.graphics.setColor(0.6, 0.8, 1)
    else
        love.graphics.setLineWidth(1)
        love.graphics.setColor(0.5, 0.7, 0.9)
    end
    love.graphics.rectangle("line", button.x, button.y, button.width, button.height)
    love.graphics.setLineWidth(1)
    
    -- Text
    love.graphics.setColor(1, 1, 1)
    local textWidth = love.graphics.getFont():getWidth(button.text)
    local textX = button.x + (button.width - textWidth) / 2
    local textY = button.y + (button.height - love.graphics.getFont():getHeight()) / 2
    love.graphics.print(button.text, textX, textY)
    
    love.graphics.setColor(1, 1, 1)
end

-- Draw all registered buttons
function Button.drawAll()
    for id, button in pairs(Button.buttons) do
        Button.draw(button)
    end
end

return Button

