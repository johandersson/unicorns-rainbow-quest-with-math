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
]]

Troll = {}

local DEFAULT_RADIUS = 24

function Troll:new(x, y, speed, radius)
    local r = radius or DEFAULT_RADIUS
    local obj = {
        x = x,
        y = y,
        speed = speed or 180,
        radius = r,
        collision_radius_sq = (r + 8) * (r + 8), -- some buffer
        bob_timer = 0,
        bob_speed = 6 + math.random() * 4,
        bob_amount = 4 + math.random() * 3,
        limb_phase = math.random() * 2 * math.pi
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Troll:reset(x, y, speed)
    self.x = x
    self.y = y
    self.speed = speed or self.speed
    self.bob_timer = 0
    self.limb_phase = math.random() * 2 * math.pi
end

function Troll:update(dt, target)
    -- vertical movement
    self.y = self.y + self.speed * dt
    -- horizontal homing towards target if provided
    if target and target.x then
        local dx = target.x - self.x
        local max_move = 120 * dt
        self.x = self.x + math.max(-max_move, math.min(max_move, dx))
    end

    -- bobbing and limb animation
    self.bob_timer = self.bob_timer + dt * self.bob_speed
    self.limb_phase = self.limb_phase + dt * (self.bob_speed * 0.9)
end

local function setColorHex(hex)
    local r = ((hex >> 16) & 0xFF) / 255
    local g = ((hex >> 8) & 0xFF) / 255
    local b = (hex & 0xFF) / 255
    love.graphics.setColor(r, g, b)
end

function Troll:draw()
    -- simple, stylized troll drawn with primitives
    local bob = math.sin(self.bob_timer) * self.bob_amount
    local cx, cy = self.x, self.y + bob
    local r = self.radius

    -- body
    love.graphics.setColor(0.38, 0.65, 0.35)
    love.graphics.ellipse('fill', cx, cy + r*0.6, r*0.9, r*0.7)

    -- arms (swinging)
    local arm_length = r * 0.9
    local arm_offset_y = cy + r*0.2
    local swing = math.sin(self.limb_phase) * (r*0.25)
    love.graphics.setColor(0.38, 0.65, 0.35)
    love.graphics.setLineWidth(math.max(2, r*0.12))
    love.graphics.line(cx - r*0.6, arm_offset_y, cx - r*0.6 - arm_length + swing, arm_offset_y + r*0.2)
    love.graphics.line(cx + r*0.6, arm_offset_y, cx + r*0.6 + arm_length - swing, arm_offset_y + r*0.2)

    -- legs
    love.graphics.setLineWidth(math.max(2, r*0.14))
    love.graphics.line(cx - r*0.3, cy + r*1.0, cx - r*0.3 + math.sin(self.limb_phase)*r*0.25, cy + r*1.6)
    love.graphics.line(cx + r*0.3, cy + r*1.0, cx + r*0.3 - math.sin(self.limb_phase)*r*0.25, cy + r*1.6)

    -- head
    love.graphics.setColor(0.9, 0.78, 0.6)
    love.graphics.circle('fill', cx, cy - r*0.6, r*0.6)

    -- ears
    love.graphics.setColor(0.9, 0.78, 0.6)
    love.graphics.polygon('fill', cx - r*0.6, cy - r*0.6, cx - r*0.9, cy - r*0.9, cx - r*0.4, cy - r*0.85)
    love.graphics.polygon('fill', cx + r*0.6, cy - r*0.6, cx + r*0.9, cy - r*0.9, cx + r*0.4, cy - r*0.85)

    -- eyes
    love.graphics.setColor(1,1,1)
    love.graphics.circle('fill', cx - r*0.18, cy - r*0.68, r*0.12)
    love.graphics.circle('fill', cx + r*0.18, cy - r*0.68, r*0.12)
    love.graphics.setColor(0,0,0)
    love.graphics.circle('fill', cx - r*0.18 + math.sin(self.bob_timer)*r*0.02, cy - r*0.68, r*0.06)
    love.graphics.circle('fill', cx + r*0.18 + math.sin(self.bob_timer+0.5)*r*0.02, cy - r*0.68, r*0.06)

    -- nose
    love.graphics.setColor(0.95,0.7,0.55)
    love.graphics.polygon('fill', cx, cy - r*0.58, cx - r*0.06, cy - r*0.44, cx + r*0.06, cy - r*0.44)

    -- mouth (simple)
    love.graphics.setColor(0.6,0.1,0.1)
    love.graphics.setLineWidth(2)
    love.graphics.arc('line', 'open', cx, cy - r*0.45, r*0.18, math.pi*0.1, math.pi*0.9)

    -- optional small tuft/horn
    love.graphics.setColor(0.7,0.4,0.2)
    love.graphics.polygon('fill', cx, cy - r*1.02, cx - r*0.06, cy - r*0.82, cx + r*0.06, cy - r*0.82)

    love.graphics.setColor(1,1,1)
    love.graphics.setLineWidth(1)
end

return Troll