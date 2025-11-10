-- World Travel System Module
-- Manages world graph, nodes, and travel between locations

local World = {}

-- Node types
World.NODE_TYPES = {
    HERB_PATCH = "herb_patch",
    OUTCROP = "outcrop",
    TIDEPOOL = "tidepool",
    BEACH = "beach",
    MIXED = "mixed" -- Nodes with multiple gathering options
}

-- World graph (based on World_Travel.md)
World.NODES = {
    start = {
        id = "start",
        name = "Starting Meadow",
        type = World.NODE_TYPES.MIXED,
        region = "Start",
        description = "A peaceful meadow where your journey begins",
        gatherPaths = {"herbalism"}, -- Available gathering paths at this node
        connections = {
            {to = "meadow", cost = 600},
            {to = "ridge", cost = 1800}
        }
    },
    
    meadow = {
        id = "meadow",
        name = "Wildflower Meadow",
        type = World.NODE_TYPES.HERB_PATCH,
        region = "Start",
        description = "A vibrant meadow filled with herbs and flowers",
        gatherPaths = {"herbalism"},
        connections = {
            {to = "start", cost = 600},
            {to = "forest", cost = 900}
        }
    },
    
    forest = {
        id = "forest",
        name = "Ancient Forest",
        type = World.NODE_TYPES.MIXED,
        region = "Start",
        description = "Dense woods with herbs and crystal formations",
        gatherPaths = {"herbalism", "crystal"},
        connections = {
            {to = "meadow", cost = 900},
            {to = "beach", cost = 1200}
        }
    },
    
    beach = {
        id = "beach",
        name = "Sandy Beach",
        type = World.NODE_TYPES.BEACH,
        region = "Coast",
        description = "A serene beach with shells and sea treasures",
        gatherPaths = {"shores"},
        connections = {
            {to = "forest", cost = 1200},
            {to = "far_coast", cost = 800}
        }
    },
    
    ridge = {
        id = "ridge",
        name = "Crystal Ridge",
        type = World.NODE_TYPES.OUTCROP,
        region = "Ridge",
        description = "Rocky highlands rich with crystal deposits",
        gatherPaths = {"crystal"},
        connections = {
            {to = "start", cost = 1800},
            {to = "cavern", cost = 1000}
        }
    },
    
    cavern = {
        id = "cavern",
        name = "Glimmering Cavern",
        type = World.NODE_TYPES.OUTCROP,
        region = "Ridge",
        description = "A cave system filled with crystals and minerals",
        gatherPaths = {"crystal"},
        connections = {
            {to = "ridge", cost = 1000},
            {to = "far_coast", cost = 2200}
        }
    },
    
    far_coast = {
        id = "far_coast",
        name = "Far Coast",
        type = World.NODE_TYPES.TIDEPOOL,
        region = "Coast",
        description = "Tide pools teeming with shells and kelp",
        gatherPaths = {"shores"},
        connections = {
            {to = "cavern", cost = 2200},
            {to = "beach", cost = 800}
        }
    }
}

-- Current location
World.currentLocation = "start"

-- Initialize world system
function World.init()
    World.currentLocation = "start"
    print("World system initialized at Starting Meadow")
end

-- Get current node
function World.getCurrentNode()
    return World.NODES[World.currentLocation]
end

-- Get available connections from current node
function World.getConnections()
    local node = World.getCurrentNode()
    if not node then return {} end
    
    local connections = {}
    for _, conn in ipairs(node.connections) do
        local targetNode = World.NODES[conn.to]
        if targetNode then
            table.insert(connections, {
                node = targetNode,
                cost = conn.cost
            })
        end
    end
    
    return connections
end

-- Check if can travel to a node
function World.canTravel(targetNodeId, stepSystem)
    local node = World.getCurrentNode()
    if not node then return false, "No current location" end
    
    -- Find connection
    local connection = nil
    for _, conn in ipairs(node.connections) do
        if conn.to == targetNodeId then
            connection = conn
            break
        end
    end
    
    if not connection then
        return false, "No path to that location"
    end
    
    -- Check if have enough steps
    local counts = stepSystem.getCounts()
    if counts.bank < connection.cost then
        return false, string.format("Need %d steps, have %d", connection.cost, counts.bank)
    end
    
    return true, connection.cost
end

-- Travel to a node
function World.travel(targetNodeId, stepSystem)
    local canTravel, costOrError = World.canTravel(targetNodeId, stepSystem)
    if not canTravel then
        return false, costOrError
    end
    
    -- Spend steps
    if not stepSystem.spend(costOrError, false) then
        return false, "Failed to spend steps"
    end
    
    -- Move to new location
    World.currentLocation = targetNodeId
    local newNode = World.getCurrentNode()
    
    return true, string.format("Traveled to %s", newNode.name)
end

-- Get available gather paths at current location
function World.getAvailableGatherPaths()
    local node = World.getCurrentNode()
    if not node then return {} end
    return node.gatherPaths or {}
end

-- Check if a gather path is available at current location
function World.isGatherPathAvailable(pathName)
    local availablePaths = World.getAvailableGatherPaths()
    for _, path in ipairs(availablePaths) do
        if path == pathName then
            return true
        end
    end
    return false
end

-- Get all regions
function World.getRegions()
    local regions = {}
    for _, node in pairs(World.NODES) do
        if not regions[node.region] then
            regions[node.region] = {}
        end
        table.insert(regions[node.region], node)
    end
    return regions
end

-- Reset world system
function World.reset()
    World.currentLocation = "start"
    print("World reset to Starting Meadow")
end

return World

