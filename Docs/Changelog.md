# Walking RPG - Development Changelog

## Phase 2.5: Activity System Refactor (IN PROGRESS)

### v0.5.0 - Activity System & Mouse-Driven UI (Current)
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

