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

-- unicorn.lua
-- Cache sprite and quads globally (singleton pattern for O(1) access)
local unicorn_sprite = nil
local quadUp = nil
local quadDown = nil
local sprite_width = 0
local sprite_height = 0

-- Pre-load sprite once (memoization for image loading)
if not unicorn_sprite then
    unicorn_sprite = love.graphics.newImage('graphics/unicorn-sprite.png')
    sprite_width, sprite_height = unicorn_sprite:getDimensions()
    quadUp = love.graphics.newQuad(0, 0, sprite_width, sprite_height/2, sprite_width, sprite_height)
    quadDown = love.graphics.newQuad(0, sprite_height/2, sprite_width, sprite_height/2, sprite_width, sprite_height)
end

Unicorn = {}

function Unicorn:new(x, y, ground, width)
    local obj = {
        x = x or 400,
        y = y or 200,
        previous_x = x or 400,
        previous_y = y or 200,
        vx = 0,
        vy = 0,
        speed = 320,
        walk_speed = 160,
        fly_speed = 320,
        gravity = 400,  -- Strong gravity for challenge
        fall_multiplier = 1.6,
        fall_boost = 120,
        width = 40,
        height = 30,
        ground = ground or 550,
        screen_width = width or 800,
        sprite = unicorn_sprite,
        quadUp = quadUp,
        quadDown = quadDown
    }
    setmetatable(obj, self)
    self.__index = self
    -- Animation state
    obj.animTimer = 0
    obj.animInterval = 0.12
    obj.current_quad = obj.quadUp
    obj.on_ground = false
    obj._was_up = false
    return obj
end

function Unicorn:update(dt)
    self.previous_x = self.x
    self.previous_y = self.y

    -- Horizontal movement (walk on ground, run in air)
    local move_speed = self.speed
    if self.on_ground then move_speed = self.walk_speed end
    if love.keyboard.isDown('left') then
        self.vx = -move_speed
    elseif love.keyboard.isDown('right') then
        self.vx = move_speed
    else
        self.vx = 0
    end

    -- Vertical movement (flying up only, gravity pulls down)
    local up = love.keyboard.isDown('up')
    if up then
        self.vy = -self.fly_speed
    else
        -- Apply stronger gravity when falling (makes falling quicker after flying)
        local gravity_to_use = self.gravity
        if self.vy > 0 then gravity_to_use = gravity_to_use * self.fall_multiplier end
        self.vy = self.vy + gravity_to_use * dt
        -- If the player just released the fly key, give a small extra downward push
        if self._was_up and not up then
            self.vy = self.vy + self.fall_boost
        end
    end

    -- Update position
    local new_x = self.x + self.vx * dt
    local new_y = self.y + self.vy * dt
    
    -- Cache half dimensions (avoid repeated division)
    local half_w = self.width * 0.5
    local half_h = self.height * 0.5
    
    -- Clamp bounds (optimized with single assignment)
    self.x = math.max(half_w, math.min(new_x, self.screen_width - half_w))
    
    -- Check ground collision BEFORE clamping
    local hit_ground = false
    if new_y + half_h >= self.ground then
        hit_ground = true
    end

    self.y = math.max(half_h, math.min(new_y, self.ground - half_h))
    if hit_ground then
        self.vy = 0
    end

    -- Update on_ground flag for animation and movement logic
    self.on_ground = hit_ground

    -- Animation: when on ground and moving horizontally, animate between quads
    if self.on_ground and math.abs(self.vx) > 0 then
        self.animTimer = self.animTimer + dt
        if self.animTimer >= self.animInterval then
            self.animTimer = self.animTimer - self.animInterval
            if self.current_quad == self.quadUp then
                self.current_quad = self.quadDown
            else
                self.current_quad = self.quadUp
            end
        end
    else
        -- Reset to idle frame when not walking
        if self.vy < 0 then
            self.current_quad = self.quadDown
        else
            self.current_quad = self.quadUp
        end
        self.animTimer = 0
    end

    -- track previous up state
    self._was_up = up

    return hit_ground
end

function Unicorn:draw()
    self:drawUnicorn()
end

function Unicorn:drawUnicorn()
    -- Ensure no accidental tinting from previous draw calls
    love.graphics.setColor(1, 1, 1, 1)
    if self.is_dying then
        -- Tint red while dying
        love.graphics.setColor(1, 0.2, 0.2, 1)
    end
    local quad = self.current_quad or (self.vy < 0 and self.quadDown or self.quadUp)
    love.graphics.draw(self.sprite, quad, self.x - self.width/2, self.y - self.height/2)
    -- Reset color to opaque white for subsequent draws
    love.graphics.setColor(1, 1, 1, 1)
end

return Unicorn