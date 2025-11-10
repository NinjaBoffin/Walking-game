# Walking RPG - Minimal Prototype

A prototype of the Walking RPG game built with LÖVE framework, featuring a boxed UI layout and modal-based crafting system.

## Features Implemented

- **Activity System** (NEW - v0.5.0): Mobile-first activity selection and management
  - Select activities based on current location
  - Set quantity targets for gathering
  - Progress tracking with auto-chaining
  - Cancel with step refund
- **Mouse-Driven UI** (NEW - v0.5.0): Click-based interaction for mobile readiness
  - Clickable buttons for all activities
  - Number pad for quantity input
  - Visual button hover states
- **Step Bank System**: Accumulate and spend steps with bank/live step separation
- **Three Gathering Paths**: 
  - Herbalism: Gather herbs, dry/press transforms
  - Crystal: Gather crystals, polish/tumble transforms
  - Shores: Gather shells, salt/kelp transforms
- **Transform System**: Multiple transform recipes across all paths using banked steps
- **Crafting System**: 
  - Consumables: Tea (cost reduction), Potion (craft queue), Snack (step refund)
  - Equipment: Pendant, Bracelet, Wrap with passive effects
- **Equipment System**: 3 equipment slots + 2 consumable slots (1 Tea + 1 Potion)
- **World Travel System**: 7 nodes across 3 regions with location-based gathering
- **Progression System**: Milestone tracking for gathers, transforms, and crafts
- **33-Slot Inventory**: Auto-merge stacks, overflow handling
- **Action State Machine**: Proper idle → gather/spend → complete flow
- **In-Game Help**: Toggle recipe guide showing all paths, transforms, item uses, and progression stats

## How to Run

1. Install [LÖVE 11.x](https://love2d.org/)
2. Navigate to the project directory
3. Run: `love .` (or drag the folder onto love.exe)

## Controls

### Mouse-Driven Interface
- **Click** - Select activities, input quantities, navigate UI
- All interactions are now mouse-based for mobile-first design

### Keyboard Shortcuts (Testing)
- **SPACE** (hold) - Simulate step accumulation (for prototype testing)
- **H** - Toggle Help/Recipes screen (includes progression stats)
- **T** - Open travel map (from activity selection screen)
- **X** - Reset game

## Gameplay Flow

### 1. Activity Selection
- View available activities based on your current location
- **Gathering**: Only paths available at your location (e.g., only Shores at Sandy Beach)
- **Transforms**: Always available (Dry/Press herbs, Polish/Tumble crystals, Extract salt/Press kelp)
- **Travel**: Move to different locations

### 2. Set Quantity Target
- Click an activity to configure it
- Use the number pad to set how many items you want (e.g., "5 herbs")
- See estimated steps needed
- Click "Start Activity" to begin

### 3. Walk & Complete
- Hold SPACE to simulate walking (in prototype)
- Watch progress toward your target
- Activity auto-completes when target is reached
- Excess steps go to your banked steps

### 4. Cancel Anytime
- Click "Cancel Activity" to stop
- Accumulated steps are refunded to your bank
- Return to activity selection

## Game Mechanics

### Step System
- **Banked Steps**: Accumulate when idle, used for transforms/crafts/travel
- **Live Steps**: Generated during active gathering, used only for gather actions
- After gathering completes, remaining live steps are added to bank

### World Travel
- **7 Nodes** across 3 regions: Start, Ridge, Coast
- **Location-based gathering**: Can only gather paths available at current node
- **Travel costs**: 600-2200 banked steps between nodes
- **Starting location**: Starting Meadow (all 3 paths available)

### Progression
- **Milestone tracking**: Gathers, transforms, crafts, and steps spent
- **Stats display**: View your progress in the Help modal (H)
- **Foundation for unlocks**: System ready for future milestone-based features

### Gathering
- Uses **live steps only** (never uses bank)
- Progress based on steps accumulated
- Outputs items to inventory

### Transforms
- Uses **banked steps first** (with live fallback)
- Requires specific input items
- Produces transformed items

### Inventory
- 33 slots maximum
- Each stack can hold up to 100 items
- Auto-merges stacks of same item type
- Overflow protection (warns if full)

## System Architecture

### Project Structure

```
Walking Game/
├── main.lua                 # Entry point, game loop, and UI
├── conf.lua                # LÖVE configuration (auto-generated)
├── README.md               # This file
├── Docs/                    # Game design documentation
│   ├── gdd.md              # Game Design Document
│   ├── Systems.md          # System specifications
│   ├── Progression.md      # Progression mechanics
│   └── ...
└── src/                     # Source code
    ├── systems/             # Core game systems
    │   ├── step_system.lua  # Step bank and live step management
    │   ├── inventory.lua    # 33-slot inventory with auto-merge
    │   ├── action_runner.lua # Action state machine (FSM)
    │   ├── crafting.lua     # Crafting recipes and logic
    │   ├── equipment.lua    # Equipment management and effects
    │   ├── world.lua        # World graph and travel system
    │   └── progression.lua  # Milestone tracking and progression
    └── paths/               # Gathering paths
        ├── herbalism.lua    # Herbalism gather path and transforms
        ├── crystal.lua      # Crystal gather path and transforms
        └── shores.lua       # Shores gather path and transforms
```

### System Components

#### Core Systems (`src/systems/`)

**StepSystem** (`step_system.lua`)
- Manages step bank (accumulated steps) and live steps (active gathering)
- Handles step accumulation, spending, and conversion
- Provides simulation mode for prototype testing
- Key functions:
  - `addToBank(amount)` - Add steps to bank
  - `spend(amount, allowLiveFallback)` - Spend steps (bank first, live fallback)
  - `addLiveSteps(amount)` - Add live steps during gathering
  - `getCounts()` - Get current bank/live step counts

**Inventory** (`inventory.lua`)
- 33-slot inventory with 100-item stack capacity
- Auto-merges stacks of same item type
- Overflow protection and capacity tracking
- Key functions:
  - `addItem(itemId, quantity)` - Add items (auto-merge)
  - `removeItem(itemId, quantity)` - Remove items
  - `getItemCount(itemId)` - Get total count of item
  - `getCapacityInfo()` - Get slot usage info

**ActionRunner** (`action_runner.lua`)
- Finite State Machine for action management
- States: `idle` → `gather_active`/`spend_active` → `complete` → `idle`
- Handles action progress, step consumption, and completion
- Key functions:
  - `startGather(action, stepSystem)` - Start gather action (uses live steps)
  - `startSpend(action, stepSystem)` - Start spend action (uses banked steps)
  - `update(dt, stepSystem)` - Update action progress, returns completed action
  - `isIdle()` - Check if no action is active

#### Gathering Paths (`src/paths/`)

All gathering paths follow the same structure and interface:

**Herbalism** (`herbalism.lua`)
- Items: herb, dried_herb, pressed_flower
- Transforms: DRY (2→1), PRESS (3→1)
- Gather cost: 100 live steps

**Crystal** (`crystal.lua`)
- Items: crystal_shard, polished_crystal, tumbled_stone
- Transforms: POLISH (2→1), TUMBLE (3→1)
- Gather cost: 120 live steps

**Shores** (`shores.lua`)
- Items: shell, sea_salt, kelp_flakes
- Transforms: SALT (2→1), PRESS (3→1)
- Gather cost: 110 live steps

**Common Interface:**
- `ITEMS` - Item definitions for the path
- `TRANSFORMS` - Transform recipes with costs
- `GATHER_CONFIG` - Gather action configuration
- `getGatherAction()` - Get gather action data
- `canTransform(type, inventory)` - Validate transform requirements
- `performTransform(type, inventory, stepSystem)` - Execute transform

### Data Flow

1. **Step Accumulation**
   - Idle: Steps accumulate in bank (`StepSystem.addToBank()`)
   - During gather: Live steps generated (`StepSystem.addLiveSteps()`)

2. **Gathering Flow**
   - User starts gather → `ActionRunner.startGather()`
   - Live steps accumulate → `ActionRunner.update()` consumes live steps
   - On completion → Items added to inventory, remaining live steps → bank

3. **Transform Flow**
   - User starts transform → `ActionRunner.startSpend()`
   - Validates requirements → `Herbalism.canTransform()`
   - Time-based progress → `ActionRunner.update()`
   - On completion → Steps spent, items transformed → `Herbalism.performTransform()`

## Next Steps

This prototype validates the core multi-path gathering loop. Next phases will add:
- Crafting system (consumables & equipment)
- World travel system with nodes
- Progression milestones and unlocks
- Mobile integration (HealthKit/Google Fit)
- Cloud sync and user profiles

