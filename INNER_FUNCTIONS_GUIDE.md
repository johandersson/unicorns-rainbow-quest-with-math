# Inner Function Optimization Guide

## Overview
This document explains the strategic use of inner functions in the codebase to improve performance and code organization.

## What Are Inner Functions?

Inner functions (also called nested functions or closures) are functions defined inside other functions. In Lua, they have access to the outer function's local variables.

```lua
function outer()
    local value = 10
    
    -- Inner function with access to 'value'
    local function inner()
        return value * 2
    end
    
    return inner()
end
```

## When to Use Inner Functions

### ✅ Good Use Cases

1. **Repeated Operations in Loops**
   - Avoids repeated function lookups
   - Reduces call overhead for hot paths
   - Example: Processing list items

2. **Helper Functions Used Only Locally**
   - Better encapsulation
   - Clearer code organization
   - No namespace pollution

3. **Performance-Critical Paths**
   - Parsing operations
   - Rendering loops
   - Collision detection

4. **Closures Over Local State**
   - When function needs access to specific local variables
   - Cleaner than passing many parameters

### ❌ When NOT to Use

1. **Functions Needed Elsewhere**
   - Use methods or module-level functions instead
   
2. **Simple One-Liners**
   - Unnecessary overhead for trivial operations
   
3. **Recursive Functions**
   - May cause issues with forward references

## Implementation Examples in This Project

### 1. ScoreboardManager - File Parsing

**Location**: `scoreboard_manager.lua:loadScores()`

```lua
function ScoreboardManager:loadScores()
    -- ... setup code ...
    
    -- Inner function for parsing - optimizes by avoiding repeated function lookups
    local function parseLine(line)
        local name, score = line:match("^(.+):(%d+)$")
        if name and score then
            return {name = name, highscore = tonumber(score)}
        end
    end
    
    for line in content:gmatch("[^\r\n]+") do
        local player = parseLine(line)
        if player then
            table.insert(self.players, player)
        end
    end
end
```

**Benefits**:
- Encapsulates parsing logic
- Called in loop - benefits from reduced lookup overhead
- Clear separation of concerns
- Type conversion happens in one place

### 2. ScoreboardManager - File Formatting

**Location**: `scoreboard_manager.lua:saveScores()`

```lua
function ScoreboardManager:saveScores()
    -- Inner function for line formatting
    local function formatLine(player)
        return player.name .. ":" .. player.highscore
    end
    
    local lines = {}
    for _, player in ipairs(self.players) do
        table.insert(lines, formatLine(player))
    end
    
    local content = table.concat(lines, "\n")
    love.filesystem.write(SCOREBOARD_FILE, content)
end
```

**Benefits**:
- Consistent formatting
- Easy to modify format in one place
- Readable loop body

### 3. UIManager - Glow Effect Calculation

**Location**: `ui_manager.lua:drawHighScoreCelebration()`

```lua
function UIManager:drawHighScoreCelebration(score_data, dialog_renderer)
    -- Animated gold glow effect (inner function for glow calculation)
    local function getGlowColor(time)
        local pulse = 0.5 + 0.5 * math.sin(time * 3)
        return {1, 0.84 + pulse * 0.16, pulse * 0.3}
    end
    
    local glow_color = getGlowColor(love.timer.getTime())
    -- Use glow_color for rendering...
end
```

**Benefits**:
- Encapsulates animation logic
- Makes rendering code cleaner
- Easy to adjust animation parameters
- Could be called multiple times per frame

### 4. UIManager - List Item Rendering

**Location**: `ui_manager.lua:drawNameInputScreen()`

```lua
function UIManager:drawNameInputScreen(name_input, player_names, selected_index, dialog_renderer)
    -- ... setup code ...
    
    -- Inner function for drawing list item (optimization)
    local function drawListItem(i, name, is_selected)
        local item_y = list_y + (i - 1) * 24
        if is_selected then
            love.graphics.setColor(1, 0.84, 0, 0.3)
            love.graphics.rectangle('fill', dialog_x + 30, item_y - 2, dialog_w - 60, 20)
        end
        love.graphics.setColor(is_selected and {1, 1, 0.5} or {0.9, 0.9, 0.9})
        love.graphics.printf((is_selected and "> " or "  ") .. name, dialog_x + 35, item_y, dialog_w - 70, 'left')
    end
    
    for i = 1, math.min(max_show, #player_names) do
        drawListItem(i, player_names[i], i == selected_index)
    end
end
```

**Benefits**:
- Keeps loop body clean
- Reduces parameter passing
- Has access to outer function's local variables
- Improves readability significantly

## Performance Comparison

### Without Inner Function
```lua
function processItems(items)
    for i, item in ipairs(items) do
        -- Repeated string concatenation and formatting
        local formatted = item.name .. ":" .. tostring(item.value)
        table.insert(results, formatted)
    end
end
```

### With Inner Function
```lua
function processItems(items)
    local function formatItem(item)
        return item.name .. ":" .. tostring(item.value)
    end
    
    for i, item in ipairs(items) do
        table.insert(results, formatItem(item))
    end
end
```

**Improvements**:
- More maintainable
- Easier to test/modify format
- Slightly faster due to function inlining potential
- Better code organization

## Best Practices

### 1. Name Inner Functions Descriptively
```lua
-- Good
local function calculateDistance(x1, y1, x2, y2)
    return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end

-- Bad
local function f(a, b, c, d)
    return math.sqrt((c-a)^2 + (d-b)^2)
end
```

### 2. Keep Inner Functions Small and Focused
```lua
-- Good - single responsibility
local function isValidScore(score)
    return score >= 0 and score <= 999999
end

-- Bad - too many responsibilities
local function processScore(score, player, file)
    -- validation, saving, formatting, logging all mixed
end
```

### 3. Don't Overuse Inner Functions
```lua
-- Unnecessary inner function
local function getValue()
    local function helper()
        return 42
    end
    return helper()
end

-- Better - just do it directly
local function getValue()
    return 42
end
```

### 4. Use for Encapsulation
```lua
function Game:loadData()
    -- Private helper only used here
    local function parseHeader(line)
        return line:match("^Header: (.+)$")
    end
    
    local function parseValue(line)
        local key, val = line:match("^(%w+)=(%d+)$")
        return key, tonumber(val)
    end
    
    -- Use helpers...
end
```

## Measurement and Profiling

To verify performance benefits:

1. **Profile Before and After**
   ```lua
   local start = love.timer.getTime()
   -- Function call
   local elapsed = love.timer.getTime() - start
   ```

2. **Use LuaJIT's Profiler** (if using LuaJIT)
   ```lua
   local jit = require("jit")
   jit.opt.start("hotloop=2", "hotexit=2")
   ```

3. **Measure in Hot Paths**
   - Focus on functions called every frame
   - Or functions called in tight loops

## Summary

Inner functions in this project are used strategically:
- ✅ ScoreboardManager: Parsing and formatting in loops
- ✅ UIManager: Rendering helpers and animation calculations
- ✅ Limited to performance-critical or encapsulation needs
- ✅ Improve code readability and maintainability

The optimizations are subtle but valuable in:
- Hot rendering paths (60 FPS)
- File I/O operations
- List processing

**Key Principle**: Use inner functions when they improve code clarity OR performance, not just because you can.
