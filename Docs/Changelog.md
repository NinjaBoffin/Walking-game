# Walking RPG - Development Changelog

## Phase 2.75: Equipment & Consumables UI

### v0.6.1 - Mobile-Friendly Modal Navigation (Current)
**Date**: November 13, 2025

**Added:**
- **X Close Button** - All modals now have a close button
  - Red X button in top-right corner of every modal
  - Hover effect (darker red when mouse over)
  - Mobile-friendly tap target (24x24 pixels)
  - Works on Help, Travel, Craft, Inventory, and Equipment modals
- **Click Outside to Close** - Mobile gesture support
  - Click/tap anywhere outside a modal to close it
  - Prevents accidental modal closure (crafting progress modal can't be closed)
  - Natural mobile UX pattern

**Changed:**
- **Button Layout** - 2x2 grid instead of 1x4
  - Row 1: [Craft/Transform] [Inventory]
  - Row 2: [Equipment] [Travel]
  - All buttons now visible without scrolling
  - Better fit for smaller screens

**Technical:**
- `currentModalBounds` - Tracks modal position/size for click detection
- `closeCurrentModal()` - Centralized modal closing logic
- `isClickOutsideModal(x, y)` - Detects clicks outside modal area
- `love.mousepressed()` - Now checks for outside clicks before button handling

---

### v0.6.0 - Equipment & Consumable System
**Date**: November 13, 2025

**Added:**
- **Equipment Management Modal** - Full equipment screen (Press E)
  - 3 equipment slots: Pendant, Bracelet, Wrap
  - Shows equipped items with effect descriptions
  - Unequip button for each slot
  - Active consumables section (Tea & Potion)
  - Duration/uses remaining display
- **Inventory Item Actions** - Use/Equip directly from inventory
  - "Use" button on consumables (tea, potion, snack)
  - "Equip" button on equipment items
  - Auto-swap handling (returns old equipment to inventory)
  - Instant activation for consumables
- **Active Effects Display** - Visual feedback on all screens
  - Shows on activity selection and active activity screens
  - Lists all equipped items
  - Displays active consumables with remaining duration/uses
  - Compact box in upper-right corner
- **Equipment Cost Reductions** - Effects actually work!
  - Equipment reduces action costs (gather, transform, craft)
  - ActionRunner applies reductions before starting actions
  - Console shows reduction percentage
  - Tea effects reduce gathering costs during duration
  - Equipment pendant reduces equipment crafting costs
- **Consumable Duration Tracking** - Effects expire properly
  - Tea effects consume steps as actions complete
  - Potion effects consume uses per craft
  - Automatic expiration when duration/uses reach 0
  - Console notifications when effects expire
- **Equipment Button** - New quick access button on main screen
  - 4 buttons now: [Craft/Transform] [Inventory] [Equipment] [Travel]
  - Keyboard shortcut: E

**Changed:**
- **Inventory Modal** - Now includes Use/Equip buttons
  - Item boxes are taller (60px) to fit buttons
  - Uses `getItemType()` helper to identify consumables/equipment
  - Materials show no button (cannot be used directly)
- **Equipment Effects** - Integrated into gameplay
  - Gather actions apply equipment cost reductions
  - Transform actions apply equipment cost reductions
  - Craft actions apply equipment cost reductions AND potion bonuses
  - Tea duration decreases after each gather action
  - Potion uses decrease after each craft action

**Technical:**
- `game.showEquipment` - Equipment modal state flag
- `drawEquipmentModal()` - Equipment management UI
- `drawActiveEffects(x, y, width)` - Reusable effects display component
- `getItemType(itemName)` - Helper to identify item categories
- `useConsumable(itemName, recipe)` - Activates consumables
- `equipItem(itemName, recipe)` - Equips equipment with auto-swap
- `ActionRunner.startGather()` - Now accepts Equipment param
- `ActionRunner.startSpend()` - Now accepts Equipment and actionType params
- `Equipment.updateConsumables(stepsSpent)` - Called after gather actions
- `Equipment.decrementPotionUses()` - Called after craft actions
- Cost reduction applied via `Equipment.getCostReduction(actionType)`

**System Integration:**
- Equipment effects are calculated in ActionRunner before action starts
- Consumable durations update in `handleActionComplete()`
- Active effects display updates in real-time
- Inventory handles equipment swapping automatically
- All modals respect modal priority (crafting progress > help > travel > craft > inventory > equipment)

---

## Phase 2.5: Activity System Refactor

### v0.5.2 - Crafting Progress & Full Click Interface
**Date**: November 10, 2025

**Added:**
- **Crafting Progress Modal** - "Set it and forget it" experience
  - 10-second timer for all crafts/transforms
  - Progress bar with visual feedback
  - Time remaining display
  - Modal shows crafting item name
  - Designed for overnight/background crafting
- **Combined Craft Menu** - Single modal for all crafting
  - Three clickable tabs: Transforms | Consumables | Equipment
  - Tab key or click to switch categories
  - Active tab has thicker border
- **All Recipes Visible** - See what you can craft
  - 6 Transform recipes always shown
  - 3 Consumable recipes always shown
  - 3 Equipment recipes always shown
  - Locked recipes show material requirements
- **Material Tracking** - Clear visual feedback
  - Green text: You have enough materials
  - Red text: Need more materials
  - Shows "X/Y item_name" format
  - [LOCKED] tag on unavailable recipes
- **Full Click Interface** - Mouse-first design
  - Click any recipe box to craft/transform
  - Hover effects on all clickable items
  - Disabled recipes are not clickable
  - No number keys needed for recipes

**Changed:**
- **Location-based gathering** - Starting Meadow now only shows Herbalism
  - Must travel to access other gathering paths
  - Crystal Ridge for crystals, Sandy Beach for shells
- **Keyboard shortcuts removed** - Only essential keys remain
  - SPACE: Simulate walking
  - H: Help
  - X: Reset
  - C/Esc: Close modals
  - Tab: Cycle craft menu tabs
- **Recipe selection** - Click-only (no 1-9 keys)
- **Craft menu button** - Renamed to "Craft/Transform"

**Fixed:**
- Recipe IDs corrected (tea_herbalism, potion_craft_queue, etc.)
- Crafting now uses `recipe.inputs` instead of `recipe.materials`
- Recipe display uses `recipe.description` for effects
- Tabs are now clickable buttons (not just visual)

**Technical:**
- `game.craftingInProgress` - Tracks active crafting
- `game.craftingTimer` - 10-second countdown
- `drawCraftingProgressModal()` - Progress display
- `getOrderedRecipes()` - Consistent recipe ordering
- Button.isActive - Tab highlighting support
- Recipe buttons with enabled/disabled states

### v0.5.1 - UI Improvements & Bug Fixes
**Date**: November 10, 2025

**Added:**
- **Inventory Modal** - Dedicated inventory screen
  - Click "Inventory" button to view all items
  - 2-column grid layout showing items and quantities
  - Slot usage display (X/33)
  - Empty state message
- **Inventory Summary** - On activity selection screen
  - Shows first 5 items with quantities
  - Slot count display
- **Resizable Window** - `conf.lua` added
  - Default size: 900x700
  - Minimum size: 800x600
  - Fully resizable
- **Transforms Modal** - Separate modal for transforms
  - Shows all 6 transform recipes
  - Recipe details (input → output, step cost)
  - Press 1-6 to perform instantly

**Changed:**
- **Fixed auto-completion bug** - Steps only accumulate when SPACE is held
- **10x faster testing** - Step accumulation multiplied by 10 for rapid testing
- **Button layout**: `[Transforms] [Inventory] [Travel]` - 3 buttons instead of 2
- **Activity selection** - Only shows gathering activities (transforms moved to modal)
- **Clear instructions** - Yellow warning: "⚠ HOLD SPACEBAR to walk and accumulate steps!"
- **Inventory display** - Shows on both selection and active screens

**Fixed:**
- Gathering no longer auto-completes - must hold SPACE to accumulate steps
- `pathModules` moved to top of file to prevent nil errors
- Step accumulation only happens when SPACE is actively held
- ActionRunner now directly modifies live steps instead of using spend()

**Technical:**
- `conf.lua` - Window configuration
- `drawInventoryModal()` - Full inventory display
- `drawTransformsModal()` - Transform selection modal
- Step simulation rate: 10 steps/sec → 100 steps/sec (10x)
- Bank accumulation: 100 steps/sec → 1000 steps/sec (10x)

### v0.5.0 - Activity System & Mouse-Driven UI
**Date**: November 10, 2025

**Added:**
- **Activity System** - Mobile-first activity selection flow
  - Activity selection screen showing only available activities at current location
  - Quantity input with number pad for setting activity targets
  - Active activity screen with progress tracking
  - Cancel functionality (refunds steps to bank)
- **Mouse-Driven UI** - Click-based interaction
  - Clickable buttons for all activities
  - Number pad for quantity input
  - Button hover states
  - Mouse click handling throughout
- **Activity Types**:
  - Gather activities (location-dependent, use live steps)
  - Transform activities (always available, instant execution)
  - Travel activity (opens travel map)

**Changed:**
- **Removed keyboard shortcuts** for gathering/transforms (1/2/3/Q/W/E/R/A/S)
- **Kept essential keys**: SPACE (simulate steps), H (help), X (reset), T (travel)
- UI now shows different screens based on activity state
- Activities track quantity targets instead of just starting actions
- Gathering auto-chains until target quantity is reached

**Technical:**
- `src/systems/activity_manager.lua` - Activity state management
- `src/ui/button.lua` - Button UI component system
- `love.mousepressed` - Mouse click handling
- Activity state machine: selection → configuring → active → selection

---

## Phase 2: Expanded Prototype - COMPLETED

Phase 2 successfully implemented all three gathering paths, crafting system with consumables and equipment, world travel with location-based gathering, and progression tracking. The prototype now has a complete game loop with meaningful choices and progression.

---

## Phase 1: Minimal Prototype - COMPLETED

### v0.4.0 - World Travel System
**Date**: November 9, 2025

**Added:**
- **World travel system** with 7 nodes across 3 regions
- **Travel map modal** (Press T) showing:
  - Current location with description
  - Available destinations with step costs
  - Color-coded affordability (green=can afford, red=too expensive)
  - Available gather paths at each location
- **Location-based gathering** - can only gather paths available at current node
- **3 Regions**: Start, Ridge, Coast
- **7 Nodes**: Starting Meadow, Wildflower Meadow, Ancient Forest, Sandy Beach, Crystal Ridge, Glimmering Cavern, Far Coast
- Travel costs: 600-2200 banked steps
- Current location displayed in Steps & Progress box

**Changed:**
- Gathering now checks if path is available at current location
- UI updated to show current location
- Added T key for travel map

**Technical:**
- `src/systems/world.lua` - World graph and travel logic
- `src/systems/progression.lua` - Milestone tracking system
- Node-based gathering restrictions
- Bidirectional travel between connected nodes
- Region and node type system
- Progression tracking integrated into gather/transform/craft completions

### v0.3.1 - UI Polish & Bug Fixes
**Date**: November 9, 2025

**Fixed:**
- Keyboard input priority - crafting menu now captures number keys correctly
- Modal overlays now work properly (help and crafting)
- Window is now resizable for better viewing

**Changed:**
- Improved keyboard handling with proper priority order
- Both modals (Help and Crafting) can be closed with Esc or their toggle key
- Crafting menu closes automatically after crafting an item

### v0.3.0 - Crafting System & UI Overhaul
**Date**: November 9, 2025

**Added:**
- **Crafting system** with consumables and equipment
- **3 Consumable types**:
  - Tea: Reduces gather costs by 8% for 900 steps
  - Potion: Adds +1 craft queue for next 3 crafts
  - Snack: Instantly refunds 100 steps
- **3 Equipment types**:
  - Pendant: Reduces equipment craft costs by 6%
  - Bracelet: 10% chance for +1 item when gathering
  - Wrap: Reduces specific transform costs by 6%
- **Equipment system** with 3 equipment slots + 2 consumable slots
- **Modal crafting menu** (Press C) - overlay on main screen
  - Tab-switching between Consumables/Equipment categories
  - Shows current inventory counts for each recipe
  - Color-coded materials (green=have, red=need)
  - Esc to close modal

**Changed:**
- **Complete UI overhaul** with boxed sections:
  - Steps & Progress box with visual progress bar
  - Inventory box with slot counter
  - Controls box with color-coded sections
- All information visible on one screen
- Crafting modal overlays main screen (no page switching)
- Updated help screen to include crafting information

**Technical:**
- `src/systems/crafting.lua` - Recipe definitions and crafting logic
- `src/systems/equipment.lua` - Equipment slots and effect management
- Effect system with cost reductions and bonus chances
- 10% cap on cost reductions per GDD specs
- UI helper functions for boxes and modals
- Progress bar visualization for active actions

### v0.2.0 - Multi-Path Gathering
**Date**: November 9, 2025

**Added:**
- Crystal gathering path with polish/tumble transforms
- Shores gathering path with salt/kelp transforms
- Unified path interface for all gathering systems
- Path-agnostic gathering and transform functions
- Updated controls for 3-path system
- **In-game help/recipe screen** (Press H) showing all recipes and item uses

**Changed:**
- Reorganized codebase into `src/systems/` and `src/paths/` folders
- Updated keyboard controls (1/2/3 for gathering, Q/W/E/R/A/S for transforms)
- Enhanced README with full system architecture documentation

**Technical:**
- All paths follow common interface pattern
- Path modules stored in lookup table for dynamic dispatch
- Each path has independent item types and transform recipes
- Toggle-able help screen overlay for recipe reference

### v0.1.0 - Core Prototype
**Date**: November 9, 2025

**Added:**
- LÖVE framework project structure
- Step bank system with bank/live step separation
- Herbalism gathering path (herbs, dried herbs, pressed flowers)
- 33-slot inventory with auto-merge and overflow handling
- Action state machine (idle → gather/spend → complete)
- Text-based UI with real-time display
- Step simulation for testing

**Core Systems:**
- `StepSystem` - Step accumulation and spending
- `Inventory` - 33-slot capacity with stacking
- `ActionRunner` - FSM for action management
- `Herbalism` - First gathering path implementation

**Game Loop:**
- Walk → Gather (live steps) → Transform (banked steps) → Inventory

---

## Upcoming Phases

### Phase 2: Crafting & World (In Planning)
- Consumables crafting (Tea, Potion, Snack)
- Equipment crafting (Pendant, Bracelet, Wrap)
- World travel system with nodes
- Progression milestones

### Phase 3: Mobile Integration
- iOS HealthKit integration
- Android Google Fit integration
- GPS spoofing detection
- Touch-friendly mobile UI

### Phase 4: Polish & Release
- Asset integration
- Cloud sync
- User profiles
- App store preparation

