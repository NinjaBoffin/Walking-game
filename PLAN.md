# Walking RPG - Development Plan

## Overview

Building a minimal playable prototype, then iteratively expanding to full MVP scope with cross-platform mobile support using LÖVE framework.

---

## Phase 1: Minimal Prototype ✅ COMPLETED

**Goal**: Text-based core loop with step counting simulation  
**Platform**: Desktop LÖVE for rapid iteration  
**Status**: ✅ Complete

### Tasks
- [x] Setup LÖVE project structure
- [x] Implement Step Bank system (accumulate/spend mechanics)
- [x] Create Herbalism gather path (press/dry transforms)
- [x] Build 33-slot inventory (auto-merge, overflow handling)
- [x] Create console-style text interface
- [x] Add Crystal gather path (polish/tumble transforms)
- [x] Add Shores gather path (salt/press transforms)
- [x] Add in-game help/recipe system

### Deliverables
- ✅ Modular codebase (`src/systems/`, `src/paths/`)
- ✅ Three gathering paths with transforms
- ✅ Step bank with live/banked separation
- ✅ 33-slot inventory system
- ✅ Action state machine (FSM)
- ✅ Recipe guide (Press H)

---

## Phase 2: Crafting & World

**Goal**: Add crafting system and world travel  
**Platform**: Desktop LÖVE  
**Status**: ✅ COMPLETED (November 9, 2025)

---

## Phase 2.5: Activity System & UI Refinement

**Goal**: Mobile-first activity system with click-based UI and crafting timers  
**Platform**: Desktop LÖVE (preparing for mobile)  
**Status**: ✅ COMPLETED (November 10, 2025)

### Tasks
- [x] Implement consumables crafting system
  - [x] Tea crafting (reduces gather step costs)
  - [x] Potion crafting (adds craft queue slots)
  - [x] Snack crafting (instant step refund)
  - [x] Active consumable slots (1 Tea + 1 Potion)
- [x] Implement equipment crafting system
  - [x] Pendant crafting (reduces equipment craft costs)
  - [x] Bracelet crafting (chance for bonus items)
  - [x] Wrap crafting (reduces transform costs)
  - [x] 3 equipment slots with passive effects
- [x] UI/UX improvements
  - [x] Boxed layout with sections
  - [x] Modal-based crafting menu
  - [x] Modal-based help screen
  - [x] Progress bar visualization
  - [x] Color-coded controls
- [x] Build world travel system
  - [x] World graph with nodes (3 regions, 7 nodes)
  - [x] Node types (Herb Patch, Outcrop, Tidepool/Beach)
  - [x] Travel costs (600-2200 banked steps)
  - [x] Current location tracking
  - [x] Location-based gathering restrictions
  - [x] Travel map modal UI
- [x] Add progression milestones
  - [x] Completion counters per path
  - [x] Steps spent tracking
  - [x] Milestone definitions (foundation for unlocks)
  - [x] Stats display in Help modal
- [x] Activity system implementation
  - [x] Activity selection screen (location-based)
  - [x] Quantity targeting for activities
  - [x] Progress tracking with auto-chaining
  - [x] Activity cancellation with step refund
  - [x] Mouse-driven button interface
- [x] Full click-based interface
  - [x] Clickable activity buttons
  - [x] Clickable recipe boxes (transforms/crafts)
  - [x] Clickable tabs for craft menu
  - [x] Hover effects on all interactive elements
  - [x] Removed keyboard shortcuts (except essentials)
- [x] Crafting progress system
  - [x] 10-second timer for crafts/transforms
  - [x] Progress modal with countdown
  - [x] "Set it and forget it" design
  - [x] Visual progress bar
- [x] Combined craft menu
  - [x] Three tabs: Transforms | Consumables | Equipment
  - [x] All recipes always visible
  - [x] Material requirement display (X/Y format)
  - [x] Locked/unlocked recipe states
  - [x] Color-coded material availability
- [x] Visual travel map
  - [x] Node-based graphical map
  - [x] Connection lines with step costs
  - [x] Color-coded nodes (current/connected/locked)
  - [x] Clickable nodes for travel

### Deliverables
- [x] Crafting module (`src/systems/crafting.lua`)
- [x] Equipment module (`src/systems/equipment.lua`)
- [x] Modal UI system with overlays
- [x] World graph module (`src/systems/world.lua`)
- [x] Progression tracker (`src/systems/progression.lua`)
- [x] Activity manager (`src/systems/activity_manager.lua`)
- [x] Button UI component (`src/ui/button.lua`)
- [x] Recipe data files for consumables/equipment
- [x] Crafting progress modal with timer system
- [x] Full mouse-driven interface

---

## Phase 2.75: Equipment & Consumables UI ✅ COMPLETED (Nov 13, 2025)

**Goal**: Add UI for equipment management and consumable usage, completing the core gameplay loop  
**Platform**: LÖVE (PC Desktop)  
**Status**: ✅ Complete

### Tasks
- [x] Equipment management UI
  - [x] Equipment modal showing 3 slots (pendant, bracelet, wrap)
  - [x] Equip/unequip functionality from inventory
  - [x] Swap equipment handling (auto-return to inventory)
  - [x] Active effects display on main screens
- [x] Consumable usage UI
  - [x] "Use" buttons in inventory for consumables
  - [x] Activate tea/potion effects
  - [x] Instant use for snacks
  - [x] Duration/uses tracking display
- [x] Equipment effects integration
  - [x] Apply cost reductions to actions
  - [x] Update ActionRunner to use Equipment bonuses
  - [x] Display reduced costs in UI
  - [x] Update consumable durations after actions
- [x] Visual feedback
  - [x] Active Effects box on all main screens
  - [x] Show equipped items and active consumables
  - [x] Display remaining duration/uses
  - [x] Equipment button on activity selection screen

### Deliverables
- [x] Updated inventory modal with Use/Equip buttons
- [x] Equipment management modal
- [x] Active effects display component
- [x] Equipment cost reduction integration in ActionRunner
- [x] Consumable duration/uses tracking
- [x] Keyboard shortcut (E) for equipment modal

---

## Phase 3: Mobile Integration

**Goal**: Cross-platform mobile setup with real step counting  
**Platform**: LÖVE with mobile bridges (iOS/Android)  
**Status**: 🔄 Pending

### Tasks
- [ ] Setup iOS HealthKit integration
  - [ ] Native bridge for step counting
  - [ ] Permission handling
  - [ ] Background step accumulation
- [ ] Setup Android Google Fit integration
  - [ ] Native bridge for step counting
  - [ ] Permission handling
  - [ ] Background step accumulation
- [ ] Implement GPS spoofing detection
  - [ ] 60-120s validation windows
  - [ ] Outdoor/Indoor/Vehicle/Spoof classification
  - [ ] Credit rules (Outdoor+Indoor OK, Vehicle/Spoof blocked)
  - [ ] Cooldown for repeated spoofing
- [ ] Create touch-friendly mobile UI
  - [ ] Touch controls for gathering/transforms
  - [ ] Responsive layout for different screen sizes
  - [ ] Mobile-optimized text sizes
- [ ] Add local persistence
  - [ ] Save/load game state
  - [ ] SQLite integration
  - [ ] Migration system

### Deliverables
- [ ] Native bridges (`bridges/ios/`, `bridges/android/`)
- [ ] Step validation module (`src/systems/step_validation.lua`)
- [ ] Mobile UI module (`src/ui/mobile.lua`)
- [ ] Persistence module (`src/systems/persistence.lua`)
- [ ] Build scripts for iOS/Android

---

## Phase 4: Polish & MVP Release

**Goal**: Production-ready MVP with cloud sync  
**Platform**: iOS/Android  
**Status**: 🔄 Pending

### Tasks
- [ ] Asset integration
  - [ ] Basic UI graphics
  - [ ] Icons for items/actions
  - [ ] Visual feedback for actions
- [ ] Cloud sync foundation
  - [ ] User profile system
  - [ ] Cloud save/load
  - [ ] Conflict resolution
- [ ] Final testing
  - [ ] Device compatibility testing
  - [ ] Performance optimization
  - [ ] Battery usage optimization
- [ ] App store preparation
  - [ ] Store listings
  - [ ] Screenshots
  - [ ] Privacy policy
  - [ ] Build signing

### Deliverables
- [ ] Asset pack (icons, UI elements)
- [ ] Cloud sync module (`src/systems/cloud_sync.lua`)
- [ ] Release builds (iOS .ipa, Android .apk)
- [ ] App store submissions

---

## Post-MVP Roadmap

### PMVP-1: Special Mechanics
- At-home Nocturne crafts
- Wardrobe/Fashion system (cosmetic)
- Vessels/Tags/Catalysts/Candles

### PMVP-2: Progression/World
- Full 7-node ladders per path
- Waystones/shortcuts
- New regions
- Rare nodes

### PMVP-3: Balance/Economy
- Effects/caps matrix
- Rarity tables
- Pacing curves
- Additional sinks
- Bundle boards

### PMVP-4: Story & Events
- Narrative routes
- Non-power fashion checks
- Festivals

### PMVP-5: Live-Ops/Monetization
- Season pass (cosmetics only)
- Cosmetic shop
- Art-only gacha (pity/dupe-dust)
- QoL subscription

### PMVP-6: Platform & Social
- Smartwatch companion
- Cloud save
- Cosmetic leaderboards
- Gifting

---

## Technical Architecture

### Current Structure
```
Walking Game/
├── main.lua                 # Entry point, game loop, UI
├── README.md               # Documentation
├── PLAN.md                 # This file
├── Docs/                   # Design documentation
└── src/
    ├── systems/            # Core game systems
    │   ├── step_system.lua
    │   ├── inventory.lua
    │   └── action_runner.lua
    └── paths/              # Gathering paths
        ├── herbalism.lua
        ├── crystal.lua
        └── shores.lua
```

### Planned Additions
```
src/
├── systems/
│   ├── crafting.lua        # Consumables/equipment crafting
│   ├── equipment.lua       # Equipment slots and effects
│   ├── world.lua           # World graph and travel
│   ├── progression.lua     # Milestones and unlocks
│   ├── persistence.lua     # Save/load
│   ├── step_validation.lua # GPS spoofing detection
│   └── cloud_sync.lua      # Cloud save/load
├── ui/
│   └── mobile.lua          # Touch-friendly UI
└── data/
    ├── recipes.lua         # Crafting recipes
    └── world_graph.lua     # World node definitions
```

---

## Development Principles

1. **Iterative**: Build, test, iterate
2. **Modular**: Keep systems independent
3. **Data-Driven**: Separate logic from data
4. **Mobile-First**: Design for mobile constraints
5. **Safety**: No pay-to-win, player-friendly mechanics
6. **Privacy**: Minimal data collection, no tracking

---

## Testing Strategy

### Phase 1 (Current)
- Developer testing only
- Desktop LÖVE testing
- Step simulation for rapid iteration

### Phase 2
- Developer testing
- Desktop LÖVE testing
- Recipe balance testing

### Phase 3
- Device testing (iOS/Android)
- Real step counting validation
- Battery usage monitoring
- Invited beta testers

### Phase 4
- Expanded beta testing
- App store beta programs
- Performance monitoring
- User feedback collection

---

## Success Metrics (MVP)

- [ ] Core loop validated (Walk → Gather → Transform → Craft)
- [ ] Step bank mechanics working correctly
- [ ] All 3 gathering paths functional
- [ ] Crafting system produces useful items
- [ ] World travel feels meaningful
- [ ] Mobile step counting accurate
- [ ] Battery usage acceptable (<5% per hour active use)
- [ ] No critical bugs
- [ ] Positive feedback from beta testers

---

## Current Status: Phase 2 - Crafting Complete ✅

**Next Action**: World Travel System & Progression Milestones

**Completed in Phase 1**:
- Step bank system with live/banked separation
- Three gathering paths (Herbalism, Crystal, Shores)
- Transform system with multiple recipes
- 33-slot inventory with auto-merge
- Action state machine
- In-game help/recipe guide
- Modular architecture

**Completed in Phase 2 (Crafting)**:
- Crafting system with 6 recipes (3 consumables, 3 equipment)
- Equipment system with slots and effects
- Modal-based UI (crafting menu, help screen)
- Boxed layout with progress bars
- Color-coded interface sections
- Complete gameplay loop: Gather → Transform → Craft → Equip/Use

**Ready for**:
- World travel system
- Progression milestones
- Node unlock mechanics


