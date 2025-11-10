# Phase 2.5: Activity System Refactor - Summary

**Status**: ✅ COMPLETED  
**Date**: November 10, 2025

## Overview

Phase 2.5 transformed the prototype from a keyboard-driven desktop game into a mobile-first experience with activity-based gameplay. This refactor aligns the prototype with the core loop described in the GDD: select an activity, set a target, walk to complete it.

## Key Changes

### 1. Activity System

**Before**: Press a key → action starts immediately → walk to complete
**After**: Select activity → set quantity target → walk to complete target → return to selection

**Activity Types**:
- **Gather** (location-dependent, uses live steps)
  - Gather Herbs, Gather Crystals, Gather Shells
  - Only available at locations with that path
  - Auto-chains until target quantity reached
  
- **Transform** (always available, instant execution)
  - Dry Herbs, Press Flowers
  - Polish Crystals, Tumble Stones
  - Extract Salt, Press Kelp
  - Uses banked steps immediately
  
- **Travel** (opens travel map modal)
  - Shows all connected nodes
  - Costs banked steps
  - Changes available gathering paths

**Activity Flow**:
```
[Activity Selection Screen]
  ↓ Click activity
[Quantity Configuration Screen]
  ↓ Enter quantity (1-99)
  ↓ Click "Start Activity"
[Active Activity Screen]
  ↓ Walk (hold SPACE in prototype)
  ↓ Progress updates automatically
  ↓ Target reached OR Cancel clicked
[Activity Selection Screen]
```

### 2. Mouse-Driven UI

**Removed Keyboard Shortcuts**:
- ❌ 1/2/3 - Gather paths
- ❌ Q/W/E/R/A/S - Transforms
- ❌ C - Crafting menu

**Kept Essential Keys**:
- ✅ SPACE - Simulate steps (testing)
- ✅ H - Help/Recipes
- ✅ T - Travel map
- ✅ X - Reset game

**New UI Components**:
- Clickable buttons with hover states
- Number pad for quantity input (0-9, backspace)
- Progress bars for items and steps
- Cancel button with step refund
- Category headers for activity organization

### 3. Location-Based Restrictions

Activities now respect location constraints:
- **Starting Meadow**: All 3 paths available
- **Wildflower Meadow / Ancient Forest**: Herbalism only
- **Crystal Ridge / Glimmering Cavern**: Crystal only
- **Sandy Beach / Far Coast**: Shores only

Transforms are always available regardless of location (use banked steps, not location-dependent).

## Technical Implementation

### New Files

**`src/systems/activity_manager.lua`** (239 lines):
- Activity state machine (selection → configuring → active)
- Activity type definitions with costs
- Quantity input handling
- Progress tracking
- Completion detection

**`src/ui/button.lua`** (96 lines):
- Button creation and registration
- Hover state management
- Click detection
- Button rendering

### Modified Files

**`main.lua`** (~1164 lines, +600 lines):
- Added 3 new screen draw functions:
  - `drawActivitySelectionScreen()` - Shows available activities
  - `drawActivityConfigurationScreen()` - Number pad for quantity input
  - `drawActiveActivityScreen()` - Progress tracking and cancel
- Added `love.mousepressed()` for click handling
- Removed keyboard gathering/transform shortcuts
- Updated action completion to auto-chain gather actions
- Integrated activity progress tracking

### Architecture

```
ActivityManager (State Machine)
    ├── selection: Show available activities
    ├── configuring: Set quantity target
    └── active: Track progress, auto-chain actions

Button System
    ├── Button.create() - Define button
    ├── Button.register() - Add to active buttons
    ├── Button.updateHover() - Mouse hover detection
    ├── Button.handleClick() - Execute callback
    └── Button.draw() - Render button

Activity Flow Integration
    ├── Activity selected → Configuration screen
    ├── Quantity confirmed → Start first action
    ├── Action completes → Update progress
    ├── Progress < target → Start next action
    └── Progress >= target → Complete activity
```

## User Experience Improvements

### Mobile-First Design
- All interactions via mouse/touch
- Large clickable buttons (50px+ height)
- Number pad for easy quantity input
- Clear visual feedback (hover states, progress bars)

### Quantity Targeting
- Set goals before walking (e.g., "I want 5 herbs")
- See estimated steps needed
- Track progress toward goal
- Auto-completion when target reached

### Cancellation & Refunds
- Cancel any time during activity
- Accumulated steps refunded to bank
- No penalty for changing plans

### Location Awareness
- Only see activities you can actually do
- Clear indication of current location
- Travel option always visible

## Testing Results

✅ Activity selection shows correct activities per location
✅ Quantity input works with number pad
✅ Gathering auto-chains until target reached
✅ Progress tracking updates correctly
✅ Cancel refunds steps to bank
✅ Travel changes available activities
✅ Mouse clicks register on all buttons
✅ Hover states work correctly
✅ Help and Travel modals still function

## Metrics

- **Lines Added**: ~900 lines
- **Lines Removed**: ~40 lines (keyboard shortcuts)
- **New Systems**: 2 (ActivityManager, Button)
- **New Screens**: 3 (Selection, Configuration, Active)
- **Activity Types**: 12 (3 gather, 6 transform, 1 travel, 2 craft categories)
- **Development Time**: ~3 hours

## Next Steps

### Immediate (Phase 3)
1. Add transform activities to configuration screen
2. Add craft activities to configuration screen
3. Implement inventory management UI (use/equip items)
4. Add visual feedback for item collection
5. Improve button styling and animations

### Mobile Integration (Phase 3)
1. iOS HealthKit integration
2. Android Google Fit integration
3. Touch gesture support
4. Responsive layout for different screen sizes
5. Background step accumulation

## Conclusion

Phase 2.5 successfully transformed the prototype into a mobile-first experience. The activity system provides a clear, goal-oriented gameplay loop that matches the GDD's vision. The mouse-driven UI is ready for touch adaptation, and the location-based activity filtering creates meaningful choices about where to travel.

The prototype is now ready for mobile platform integration in Phase 3.

