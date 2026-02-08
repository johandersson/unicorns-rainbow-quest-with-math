--[[
  Rainbow Quest - Unicorn Flight with Math
  Copyright (C) 2026 Johan Andersson

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program. If not, see <https://www.gnu.org/licenses/>.
--]]

Troll = {}

local troll_image = nil
local troll_quads = nil  -- Cache all 12 frames for O(1) access
local frame_width = 0
local frame_height = 0
local TROLL_SCALE = 0.75  -- Make troll 25% smaller to fit better in background
local TROLL_COLLISION_RADIUS_SQ = 784  -- 28^2 - tighter collision (was 1600)
local FRAMES_COUNT = 12
local ANIMATION_SPEED = 0.08  -- Seconds per frame (12.5 fps)

-- Load troll sprite sheet and pre-cache all quads once (singleton pattern)
if not troll_image then
    troll_image = love.graphics.newImage('graphics/troll.png')
    local sprite_width, sprite_height = troll_image:getDimensions()
    
    -- Determine layout based on aspect ratio (detect 4x3, 3x4, 6x2, 2x6, 12x1, or 1x12)
    local cols, rows
    if sprite_width > sprite_height then
        -- Wider sprite: try 12x1, 6x2, 4x3
        if sprite_width / sprite_height > 5 then
            cols, rows = 12, 1
        elseif sprite_width / sprite_height > 2 then
            cols, rows = 6, 2
        else
            cols, rows = 4, 3
        end
    else
        -- Taller sprite: try 1x12, 2x6, 3x4
        if sprite_height / sprite_width > 5 then
            cols, rows = 1, 12
        elseif sprite_height / sprite_width > 2 then
            cols, rows = 2, 6
        else
            cols, rows = 3, 4
        end
    end
    
    frame_width = sprite_width / cols
    frame_height = sprite_height / rows
    
    -- Pre-cache all 12 quads for O(1) frame access
    troll_quads = {}
    for i = 0, FRAMES_COUNT - 1 do
        local col = i % cols
        local row = math.floor(i / cols)
        troll_quads[i + 1] = love.graphics.newQuad(
            col * frame_width,
            row * frame_height,
            frame_width,
            frame_height,
            sprite_width,
            sprite_height
        )
    end
end

function Troll:new(x, y, speed)
    local obj = {
        x = x,
        y = y,
        speed = speed,
        anim_timer = 0,  -- Animation timer for frame cycling
        current_frame = 1  -- Current animation frame (1-12)
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Troll:reset(x, y, speed)
    self.x = x
    self.y = y
    self.speed = speed
    self.anim_timer = 0
    self.current_frame = 1
end

function Troll:update(dt, target)
    -- vertical movement
    self.y = self.y + self.speed * dt
    -- horizontal homing towards target if provided (makes trolls harder to escape)
    if target and target.x then
        local dx = target.x - self.x
        -- Pre-calculate homing displacement (memoize constant multiplication)
        local max_move = 120 * dt
        -- Clamp movement (optimized single-pass clamping)
        self.x = self.x + math.max(-max_move, math.min(max_move, dx))
    end
    
    -- Animation cycling through frames 1-12 (O(1) frame calculation)
    self.anim_timer = self.anim_timer + dt
    if self.anim_timer >= ANIMATION_SPEED then
        self.anim_timer = self.anim_timer - ANIMATION_SPEED
        self.current_frame = (self.current_frame % FRAMES_COUNT) + 1  -- Cycle 1->12->1
    end
end

function Troll:draw()
    love.graphics.setColor(1,1,1)
    -- O(1) quad lookup from pre-cached array
    love.graphics.draw(
        troll_image,
        troll_quads[self.current_frame],
        self.x,
        self.y,
        0,
        TROLL_SCALE,
        TROLL_SCALE,
        frame_width / 2,
        frame_height / 2
    )
end

return Troll