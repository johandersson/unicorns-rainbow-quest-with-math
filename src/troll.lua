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

local DEFAULT_RADIUS = 24

-- Localize frequently used functions for performance (O(1) per call reductions)
local lg = love.graphics
local sin = math.sin
local cos = math.cos
local floor = math.floor
local ceil = math.ceil
local max = math.max
local min = math.min

-- Cache tables for canvases and precomputed geometry per-radius
Troll._canvas_cache = Troll._canvas_cache or {}
Troll._geom_cache = Troll._geom_cache or {}

-- Ensure cache for a given radius exists. Returns (canvas_entry, geom_entry)
local function ensureCache(rr)
    local key = floor(rr)
    local c = Troll._canvas_cache[key]
    if c then
        return c, Troll._geom_cache[key]
    end

    local cw = ceil(rr * 3)
    local ch = ceil(rr * 3)
    local canvas = lg.newCanvas(cw, ch)
    local prev = lg.getCanvas()
    lg.setCanvas(canvas)
    lg.clear(0,0,0,0)

    local ox = cw / 2
    local oy = ch / 2
    -- body
    lg.setColor(0.30, 0.55, 0.30) -- slightly darker green for meaner look
    lg.ellipse('fill', ox, oy + rr*0.6, rr*0.9, rr*0.7)

    -- head base
    lg.setColor(0.85, 0.72, 0.5)
    lg.circle('fill', ox, oy - rr*0.6, rr*0.6)
    -- ears
    lg.polygon('fill', ox - rr*0.6, oy - rr*0.6, ox - rr*0.9, oy - rr*0.9, ox - rr*0.4, oy - rr*0.85)
    lg.polygon('fill', ox + rr*0.6, oy - rr*0.6, ox + rr*0.9, oy - rr*0.9, ox + rr*0.4, oy - rr*0.85)

    -- tuft
    lg.setColor(0.6,0.35,0.15)
    lg.polygon('fill', ox, oy - rr*1.02, ox - rr*0.06, oy - rr*0.82, ox + rr*0.06, oy - rr*0.82)

    -- mouth (dark) and static sharp teeth (white triangles)
    local mouth_top_y = oy - rr*0.45
    local mouth_w = rr * 0.5
    lg.setColor(0.55, 0.05, 0.05)
    lg.rectangle('fill', ox - mouth_w, mouth_top_y, mouth_w*2, rr*0.22)
    -- teeth: several small triangles across mouth
    lg.setColor(1,1,1)
    local teeth_count = 5
    local t_w = (mouth_w*2) / (teeth_count * 2)
    for i = 1, teeth_count do
        local tx = ox - mouth_w + (i-1) * (2*t_w) + t_w*0.1
        local y1 = mouth_top_y
        local y2 = mouth_top_y + rr*0.22
        lg.polygon('fill', tx, y1, tx + t_w, y2, tx + 2*t_w, y1)
    end

    lg.setColor(1,1,1)
    lg.setLineWidth(1)
    lg.setCanvas(prev)

    c = {canvas = canvas, w = cw, h = ch}
    local geom = {
        w = cw,
        h = ch,
        ox = ox,
        oy = oy,
        arm_length = rr * 0.9,
        leg_y_offset = rr * 1.0,
        head_offset_y = -rr*0.6
    }
    Troll._canvas_cache[key] = c
    Troll._geom_cache[key] = geom
    return c, geom
end

function Troll:new(x, y, speed, radius)
    local r = radius or DEFAULT_RADIUS
    local obj = {
        x = x,
        y = y,
        speed = speed or 180,
        radius = r,
        collision_radius_sq = (r + 2) * (r + 2), -- smaller buffer to avoid surprising hits
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
        -- soften homing so trolls don't snap too aggressively to the player
        local max_move = 80 * dt
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
    local bob = sin(self.bob_timer) * self.bob_amount
    local cx, cy = self.x, self.y + bob
    local r = self.radius

    local cache_entry, geom = ensureCache(r)

    -- draw cached canvas centered at troll position
    lg.setColor(1,1,1)
    lg.draw(cache_entry.canvas, cx, cy, 0, 1, 1, cache_entry.w/2, cache_entry.h/2)

    -- dynamic limb animation using precomputed geometry
    local arm_length = geom.arm_length
    local falling = (self.speed or 0) > 260
    local arm_base_y = cy + (falling and (-r*0.1) or (r*0.2))
    local wave = sin(self.limb_phase) * (r*0.25) * (falling and 1.8 or 1.0)
    lg.setColor(0.38, 0.65, 0.35)
    lg.setLineWidth(max(2, r*0.12))

    local l_sh_x, l_sh_y = cx - r*0.6, arm_base_y
    local l_tip_x = l_sh_x - arm_length * (0.6 + 0.2 * sin(self.limb_phase))
    local l_tip_y = l_sh_y + r*0.2 + wave
    lg.line(l_sh_x, l_sh_y, l_tip_x, l_tip_y)

    local r_sh_x, r_sh_y = cx + r*0.6, arm_base_y
    local r_tip_x = r_sh_x + arm_length * (0.6 + 0.2 * sin(self.limb_phase + 1.2))
    local r_tip_y = r_sh_y + r*0.2 - wave
    lg.line(r_sh_x, r_sh_y, r_tip_x, r_tip_y)

    -- legs (subtle swing)
    lg.setLineWidth(max(2, r*0.14))
    lg.line(cx - r*0.3, cy + r*1.0, cx - r*0.3 + sin(self.limb_phase)*r*0.25, cy + r*1.6)
    lg.line(cx + r*0.3, cy + r*1.0, cx + r*0.3 - sin(self.limb_phase)*r*0.25, cy + r*1.6)

    -- angry eyes: narrow white slits + slanted eyebrows for angry look
    local eye_offset_x = r*0.18
    local eye_y = cy - r*0.68
    local pupil_x_offset = sin(self.limb_phase) * r*0.02

    -- white eye slits (smaller, more menacing)
    lg.setColor(1,1,1)
    lg.ellipse('fill', cx - eye_offset_x, eye_y + sin(self.bob_timer)*r*0.006, r*0.08, r*0.04)
    lg.ellipse('fill', cx + eye_offset_x, eye_y + sin(self.bob_timer+0.5)*r*0.006, r*0.08, r*0.04)

    -- pupils (black, centered but jittered for menace)
    lg.setColor(0,0,0)
    lg.circle('fill', cx - eye_offset_x + pupil_x_offset, eye_y, r*0.03)
    lg.circle('fill', cx + eye_offset_x + pupil_x_offset, eye_y, r*0.03)

    -- slanted angry eyebrows (dark lines)
    lg.setColor(0.1,0.05,0.05)
    lg.setLineWidth(max(1, r*0.06))
    lg.line(cx - eye_offset_x - r*0.06, eye_y - r*0.08, cx - eye_offset_x + r*0.06, eye_y - r*0.02)
    lg.line(cx + eye_offset_x + r*0.06, eye_y - r*0.08, cx + eye_offset_x - r*0.06, eye_y - r*0.02)
    lg.setLineWidth(1)

    -- nose/cheek highlight (kept subtle)
    lg.setColor(0.9,0.6,0.45)
    lg.polygon('fill', cx, cy - r*0.58, cx - r*0.06, cy - r*0.44, cx + r*0.06, cy - r*0.44)

    -- mouth outline (dark) to emphasize teeth
    lg.setColor(0.5, 0.05, 0.05)
    lg.setLineWidth(2)
    lg.rectangle('line', cx - r*0.5, cy - r*0.45, r*1.0, r*0.22)
    lg.setLineWidth(1)
end

return Troll