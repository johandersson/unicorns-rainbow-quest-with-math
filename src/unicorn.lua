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
        vx = 0,
        vy = 0,
        speed = 260,
        gravity = 400,  -- Strong gravity for challenge
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
    return obj
end

function Unicorn:update(dt)
    -- Horizontal movement
    if love.keyboard.isDown('left') then
        self.vx = -self.speed
    elseif love.keyboard.isDown('right') then
        self.vx = self.speed
    else
        self.vx = 0
    end

    -- Vertical movement (flying up only, gravity pulls down)
    if love.keyboard.isDown('up') then
        self.vy = -self.speed
    else
        -- Apply gravity
        self.vy = self.vy + self.gravity * dt
    end

    -- Update position
    local new_x = self.x + self.vx * dt
    local new_y = self.y + self.vy * dt
    
    -- Cache half dimensions (avoid repeated division)
    local half_w = self.width * 0.5
    local half_h = self.height * 0.5
    
    -- Clamp bounds (optimized with single assignment)
    self.x = math.max(half_w, math.min(new_x, self.screen_width - half_w))
    
    -- Check ground collision BEFORE clamping (only die if actually hitting ground)
    local hit_ground = false
    if new_y + half_h >= self.ground then
        hit_ground = true
    end
    
    self.y = math.max(half_h, math.min(new_y, self.ground - half_h))
    
    return hit_ground
end

function Unicorn:draw()
    self:drawUnicorn()
end

function Unicorn:drawUnicorn()
    local quad = self.vy < 0 and self.quadDown or self.quadUp
    love.graphics.draw(self.sprite, quad, self.x - self.width/2, self.y - self.height/2)
end

return Unicorn