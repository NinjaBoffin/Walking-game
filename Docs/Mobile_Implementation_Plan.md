# Mobile Implementation Plan - Phase 3

## 🎯 Goal
Get Walking RPG running on mobile devices (Android first, iOS second) with real pedometer integration.

---

## 📱 Platform Choice: LÖVE Mobile

### Why LÖVE?
- ✅ We're already using LÖVE for desktop
- ✅ Official Android support (love-android)
- ✅ Official iOS support (love-ios)
- ✅ Same Lua codebase across all platforms
- ✅ Can add native bridges for pedometer access
- ❌ Requires custom build (not on app stores by default)

### Alternatives Considered
- **React Native**: Would require complete rewrite
- **Flutter**: Would require complete rewrite
- **Godot**: Would require significant porting
- **Native (Java/Swift)**: Would require complete rewrite × 2

**Decision: Stick with LÖVE + Native Bridges**

---

## 🛠️ Implementation Strategy

### Week 1: Get LÖVE Running on Android

#### Step 1: Setup Android Development Environment
```bash
# Install Android Studio
# Download from: https://developer.android.com/studio

# Install Android SDK (via Android Studio)
# - SDK Platform 30+ (Android 11+)
# - Build Tools 30.0.3+
# - Android SDK Platform-Tools
# - Android SDK Command-line Tools
```

#### Step 2: Clone and Setup love-android
```bash
cd ~/projects
git clone https://github.com/love2d/love-android.git
cd love-android

# Copy our game into the assets folder
mkdir -p app/src/main/assets
cp -r "Walking Game"/* app/src/main/assets/
```

#### Step 3: Configure Build
Edit `app/build.gradle`:
```gradle
android {
    defaultConfig {
        applicationId "com.ninjaboffin.walkingrpg"
        minSdkVersion 21  // Android 5.0+
        targetSdkVersion 33
        versionCode 1
        versionName "0.6.1"
    }
}
```

Edit `app/src/main/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.ninjaboffin.walkingrpg">
    
    <!-- Pedometer permissions -->
    <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
    <uses-permission android:name="android.permission.BODY_SENSORS" />
    
    <application
        android:label="Walking RPG"
        android:icon="@drawable/ic_launcher">
        <!-- ... -->
    </application>
</manifest>
```

#### Step 4: Build and Test
```bash
# Build APK
./gradlew assembleDebug

# Install on connected device
adb install app/build/outputs/apk/debug/app-debug.apk

# Or use Android Studio's "Run" button
```

#### Step 5: UI Adjustments for Mobile
Create `src/systems/mobile_config.lua`:
```lua
local MobileConfig = {}

-- Detect if running on mobile
MobileConfig.isMobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS"

-- Scale factors
MobileConfig.textScale = MobileConfig.isMobile and 1.5 or 1.0
MobileConfig.buttonScale = MobileConfig.isMobile and 1.5 or 1.0
MobileConfig.minTouchSize = 48 -- 48dp minimum touch target

function MobileConfig.scaleText(size)
    return math.floor(size * MobileConfig.textScale)
end

function MobileConfig.scaleButton(width, height)
    return math.floor(width * MobileConfig.buttonScale), 
           math.floor(height * MobileConfig.buttonScale)
end

return MobileConfig
```

Update `main.lua` to use scaled sizes:
```lua
local MobileConfig = require("src.systems.mobile_config")

-- In button creation:
local btnWidth, btnHeight = MobileConfig.scaleButton(150, 50)
local btn = Button.create("id", x, y, btnWidth, btnHeight, "Text", callback)

-- In text rendering:
local font = love.graphics.newFont(MobileConfig.scaleText(14))
```

---

### Week 2: Pedometer Integration

#### Step 1: Create Android Pedometer Bridge

Create `app/src/main/java/org/love2d/android/PedometerBridge.java`:
```java
package org.love2d.android;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.util.Log;

public class PedometerBridge implements SensorEventListener {
    private static final String TAG = "PedometerBridge";
    private SensorManager sensorManager;
    private Sensor stepSensor;
    private int totalSteps = 0;
    private int initialSteps = -1;
    
    public PedometerBridge(Context context) {
        sensorManager = (SensorManager) context.getSystemService(Context.SENSOR_SERVICE);
        stepSensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER);
        
        if (stepSensor != null) {
            sensorManager.registerListener(this, stepSensor, SensorManager.SENSOR_DELAY_NORMAL);
            Log.d(TAG, "Step sensor registered");
        } else {
            Log.e(TAG, "Step sensor not available");
        }
    }
    
    @Override
    public void onSensorChanged(SensorEvent event) {
        if (event.sensor.getType() == Sensor.TYPE_STEP_COUNTER) {
            int steps = (int) event.values[0];
            
            if (initialSteps == -1) {
                initialSteps = steps;
            }
            
            totalSteps = steps - initialSteps;
            Log.d(TAG, "Steps: " + totalSteps);
        }
    }
    
    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
        // Not needed
    }
    
    public int getSteps() {
        return totalSteps;
    }
    
    public void resetSteps() {
        initialSteps = (int) totalSteps;
        totalSteps = 0;
    }
    
    public void destroy() {
        if (sensorManager != null && stepSensor != null) {
            sensorManager.unregisterListener(this);
        }
    }
}
```

#### Step 2: Expose to Lua via JNI

Update `app/src/main/java/org/love2d/android/GameActivity.java`:
```java
public class GameActivity extends SDLActivity {
    private PedometerBridge pedometerBridge;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        pedometerBridge = new PedometerBridge(this);
    }
    
    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (pedometerBridge != null) {
            pedometerBridge.destroy();
        }
    }
    
    // JNI methods called from Lua
    public static native int getSteps();
    public static native void resetSteps();
    
    static {
        // Implementation
        getSteps = () -> {
            if (pedometerBridge != null) {
                return pedometerBridge.getSteps();
            }
            return 0;
        };
    }
}
```

#### Step 3: Create Lua Binding

Create `src/systems/mobile_steps.lua`:
```lua
local MobileSteps = {}

-- Check if we're on mobile
local isMobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS"

-- Store last known step count
MobileSteps.lastStepCount = 0
MobileSteps.sessionStartSteps = 0
MobileSteps.updateInterval = 5.0 -- Check every 5 seconds
MobileSteps.timeSinceUpdate = 0

function MobileSteps.init()
    if isMobile then
        -- Get initial step count
        local success, steps = pcall(function()
            return love.system.call("getSteps") -- Custom LÖVE binding
        end)
        
        if success then
            MobileSteps.sessionStartSteps = steps
            MobileSteps.lastStepCount = steps
            print(string.format("Mobile steps initialized: %d", steps))
        else
            print("Warning: Could not access step counter")
        end
    end
end

function MobileSteps.update(dt, stepSystem)
    if not isMobile then
        return
    end
    
    MobileSteps.timeSinceUpdate = MobileSteps.timeSinceUpdate + dt
    
    if MobileSteps.timeSinceUpdate >= MobileSteps.updateInterval then
        MobileSteps.timeSinceUpdate = 0
        
        -- Get current step count
        local success, currentSteps = pcall(function()
            return love.system.call("getSteps")
        end)
        
        if success and currentSteps then
            local stepDelta = currentSteps - MobileSteps.lastStepCount
            
            if stepDelta > 0 then
                -- Add steps to bank (mobile steps = banked steps)
                stepSystem.addToBank(stepDelta)
                print(string.format("Added %d steps to bank (total: %d)", stepDelta, currentSteps))
            end
            
            MobileSteps.lastStepCount = currentSteps
        end
    end
end

function MobileSteps.getTotalSteps()
    if isMobile then
        local success, steps = pcall(function()
            return love.system.call("getSteps")
        end)
        return success and steps or 0
    end
    return 0
end

function MobileSteps.getSessionSteps()
    return MobileSteps.lastStepCount - MobileSteps.sessionStartSteps
end

return MobileSteps
```

#### Step 4: Integrate into Main Game Loop

Update `main.lua`:
```lua
local MobileSteps = require("src.systems.mobile_steps")

function love.load()
    -- ... existing code ...
    
    -- Initialize mobile steps
    MobileSteps.init()
end

function love.update(dt)
    -- ... existing code ...
    
    -- Update mobile step counter
    MobileSteps.update(dt, StepSystem)
    
    -- ... rest of update ...
end

-- Add debug display
function drawDebugOverlay()
    if MobileConfig.isMobile then
        local y = 10
        love.graphics.print("DEBUG MODE", 10, y)
        y = y + 20
        love.graphics.print(string.format("Session Steps: %d", MobileSteps.getSessionSteps()), 10, y)
        y = y + 20
        love.graphics.print(string.format("Total Steps: %d", MobileSteps.getTotalSteps()), 10, y)
    end
end
```

---

### Week 3: Persistence & Background

#### Save System
Create `src/systems/persistence.lua`:
```lua
local Persistence = {}
local json = require("lib.json") -- Add JSON library

function Persistence.getSavePath()
    return love.filesystem.getSaveDirectory() .. "/save.json"
end

function Persistence.save(gameState)
    local data = {
        version = "0.6.1",
        timestamp = os.time(),
        
        -- Step system
        bankedSteps = gameState.stepSystem.bankedSteps,
        
        -- Inventory
        inventory = gameState.inventory.getAllItems(),
        
        -- Equipment
        equipped = gameState.equipment.equipped,
        activeConsumables = gameState.equipment.activeConsumables,
        
        -- World
        currentLocation = gameState.world.currentNode,
        
        -- Progression
        progression = gameState.progression.data,
        
        -- Mobile
        lastStepCount = MobileSteps.lastStepCount
    }
    
    local jsonData = json.encode(data)
    love.filesystem.write("save.json", jsonData)
    print("Game saved")
end

function Persistence.load()
    local fileData = love.filesystem.read("save.json")
    if not fileData then
        print("No save file found")
        return nil
    end
    
    local data = json.decode(fileData)
    print(string.format("Loaded save from %s", os.date("%c", data.timestamp)))
    return data
end

return Persistence
```

---

### Week 4: Testing & Polish

#### Test Checklist
- [ ] Build APK successfully
- [ ] Install on physical Android device
- [ ] App launches without crashes
- [ ] Touch input works (buttons, modals)
- [ ] Step counter shows real steps
- [ ] Walk 100 steps, verify count updates
- [ ] Close app, walk 50 steps, reopen → verify 50 steps added to bank
- [ ] Save/load preserves inventory and progress
- [ ] Battery drain is acceptable (<5% per hour of idle)

---

## 🚀 Getting Started (Next Steps)

### Immediate Action Items:

1. **Install Android Studio** (if not already installed)
2. **Clone love-android repository**
3. **Copy game files to assets folder**
4. **Build first APK**
5. **Test on device**

### Commands to Run:
```bash
# 1. Clone love-android
git clone https://github.com/love2d/love-android.git
cd love-android

# 2. Copy game files
mkdir -p app/src/main/assets
cp -r "../Walking Game"/* app/src/main/assets/

# 3. Build
./gradlew assembleDebug

# 4. Install (device must be connected via USB)
adb install app/build/outputs/apk/debug/app-debug.apk
```

---

## 📚 Resources

- **LÖVE Android**: https://github.com/love2d/love-android
- **LÖVE iOS**: https://github.com/love2d/love-ios
- **Android Step Counter**: https://developer.android.com/guide/topics/sensors/sensors_motion#java
- **iOS CoreMotion**: https://developer.apple.com/documentation/coremotion/cmpedometer

---

## ⚠️ Potential Issues

### Issue 1: Step Sensor Not Available
**Solution**: Some old devices don't have step sensors. Add fallback to accelerometer-based step detection.

### Issue 2: Permission Denied
**Solution**: Ensure ACTIVITY_RECOGNITION permission is requested at runtime (Android 10+)

### Issue 3: Large APK Size
**Solution**: LÖVE APKs are ~15-20MB. This is acceptable for initial builds.

### Issue 4: iOS Requires Mac
**Solution**: Focus on Android first. iOS can be added later if Mac is available.

---

## 🎯 Success Criteria

Phase 3 is complete when:
- ✅ Game runs on Android device
- ✅ Real step counter updates every 5 seconds
- ✅ Steps accumulate in bank while playing
- ✅ Background steps are added when app reopens
- ✅ Save/load works reliably
- ✅ Battery drain is minimal

