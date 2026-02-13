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
    local r = (math.floor(hex / 65536) % 256) / 255
    local g = (math.floor(hex / 256) % 256) / 255
    local b = (hex % 256) / 255
    love.graphics.setColor(r, g, b)
end

function Troll:draw()
    -- Use cached canvas when available (keyed by radius)
    local bob = math.sin(self.bob_timer) * self.bob_amount
    local cx, cy = self.x, self.y + bob
    local r = self.radius

    Troll._canvas_cache = Troll._canvas_cache or {}
    local key = tostring(math.floor(r))
    local cache_entry = Troll._canvas_cache[key]
    if not cache_entry then
        -- create a temporary canvas and render the troll once
        local cw = math.ceil(r * 3)
        local ch = math.ceil(r * 3)
        local canvas = love.graphics.newCanvas(cw, ch)
        local prev_canvas = love.graphics.getCanvas()
        love.graphics.setCanvas(canvas)
        love.graphics.clear(0,0,0,0)

        -- draw at center of canvas
        local ox = cw / 2
        local oy = ch / 2
        local rr = r

        -- static parts: body and head base (arms/legs/eyes drawn dynamically for animation)
        love.graphics.setColor(0.38, 0.65, 0.35)
        love.graphics.ellipse('fill', ox, oy + rr*0.6, rr*0.9, rr*0.7)

        -- head base
        love.graphics.setColor(0.9, 0.78, 0.6)
        love.graphics.circle('fill', ox, oy - rr*0.6, rr*0.6)

        -- ears (static)
        love.graphics.setColor(0.9, 0.78, 0.6)
        love.graphics.polygon('fill', ox - rr*0.6, oy - rr*0.6, ox - rr*0.9, oy - rr*0.9, ox - rr*0.4, oy - rr*0.85)
        love.graphics.polygon('fill', ox + rr*0.6, oy - rr*0.6, ox + rr*0.9, oy - rr*0.9, ox + rr*0.4, oy - rr*0.85)

        -- tuft (static)
        love.graphics.setColor(0.7,0.4,0.2)
        love.graphics.polygon('fill', ox, oy - rr*1.02, ox - rr*0.06, oy - rr*0.82, ox + rr*0.06, oy - rr*0.82)

        love.graphics.setColor(1,1,1)
        love.graphics.setLineWidth(1)

        love.graphics.setCanvas(prev_canvas)

        cache_entry = {canvas = canvas, w = cw, h = ch}
        Troll._canvas_cache[key] = cache_entry
    end

    -- draw cached canvas centered at troll position
    love.graphics.setColor(1,1,1)
    love.graphics.draw(cache_entry.canvas, cx, cy, 0, 1, 1, cache_entry.w/2, cache_entry.h/2)

    -- draw dynamic limbs and facial details so they can animate
    local arm_length = r * 0.9
    -- If falling fast (higher speed) raise arms and increase wave
    local falling = (self.speed or 0) > 260
    local arm_base_y = cy + (falling and (-r*0.1) or (r*0.2))
    local wave = math.sin(self.limb_phase) * (r*0.25) * (falling and 1.8 or 1.0)
    love.graphics.setColor(0.38, 0.65, 0.35)
    love.graphics.setLineWidth(math.max(2, r*0.12))
    -- left arm: from shoulder to animated tip
    local l_sh_x, l_sh_y = cx - r*0.6, arm_base_y
    local l_tip_x = l_sh_x - arm_length * (0.6 + 0.2 * math.sin(self.limb_phase))
    local l_tip_y = l_sh_y + r*0.2 + wave
    love.graphics.line(l_sh_x, l_sh_y, l_tip_x, l_tip_y)
    -- right arm
    local r_sh_x, r_sh_y = cx + r*0.6, arm_base_y
    local r_tip_x = r_sh_x + arm_length * (0.6 + 0.2 * math.sin(self.limb_phase + 1.2))
    local r_tip_y = r_sh_y + r*0.2 - wave
    love.graphics.line(r_sh_x, r_sh_y, r_tip_x, r_tip_y)

    -- legs (subtle swing)
    love.graphics.setLineWidth(math.max(2, r*0.14))
    love.graphics.line(cx - r*0.3, cy + r*1.0, cx - r*0.3 + math.sin(self.limb_phase)*r*0.25, cy + r*1.6)
    love.graphics.line(cx + r*0.3, cy + r*1.0, cx + r*0.3 - math.sin(self.limb_phase)*r*0.25, cy + r*1.6)

    -- eyes and nose (small dynamic touches)
    love.graphics.setColor(1,1,1)
    love.graphics.circle('fill', cx - r*0.18, cy - r*0.68 + math.sin(self.bob_timer)*r*0.01, r*0.12)
    love.graphics.circle('fill', cx + r*0.18, cy - r*0.68 + math.sin(self.bob_timer+0.5)*r*0.01, r*0.12)
    love.graphics.setColor(0,0,0)
    love.graphics.circle('fill', cx - r*0.18 + math.sin(self.bob_timer)*r*0.02, cy - r*0.68, r*0.06)
    love.graphics.circle('fill', cx + r*0.18 + math.sin(self.bob_timer+0.5)*r*0.02, cy - r*0.68, r*0.06)
    love.graphics.setColor(0.95,0.7,0.55)
    love.graphics.polygon('fill', cx, cy - r*0.58, cx - r*0.06, cy - r*0.44, cx + r*0.06, cy - r*0.44)
    love.graphics.setColor(0.6,0.1,0.1)
    love.graphics.setLineWidth(2)
    love.graphics.arc('line', 'open', cx, cy - r*0.45, r*0.18, math.pi*0.1, math.pi*0.9)
    love.graphics.setLineWidth(1)
end

return Troll