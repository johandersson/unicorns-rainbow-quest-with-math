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

local troll_canvas = nil
local TROLL_SIZE = 40
local TROLL_COLLISION_RADIUS_SQ = 784  -- 28^2 - tighter collision (was 1600)

-- Pre-render troll graphic once
if not troll_canvas then
    troll_canvas = love.graphics.newCanvas(TROLL_SIZE, TROLL_SIZE)
    love.graphics.setCanvas(troll_canvas)
    love.graphics.clear(0,0,0,0)
    love.graphics.setColor(0, 0.8, 0) -- green body
    love.graphics.circle('fill', TROLL_SIZE/2, TROLL_SIZE/2, 20)
    love.graphics.setColor(1, 0, 0) -- red eyes
    love.graphics.circle('fill', TROLL_SIZE/2 - 6, TROLL_SIZE/2 - 6, 4)
    love.graphics.circle('fill', TROLL_SIZE/2 + 6, TROLL_SIZE/2 - 6, 4)
    love.graphics.setColor(0, 0, 0) -- black pupils
    love.graphics.circle('fill', TROLL_SIZE/2 - 6, TROLL_SIZE/2 - 6, 2)
    love.graphics.circle('fill', TROLL_SIZE/2 + 6, TROLL_SIZE/2 - 6, 2)
    love.graphics.setCanvas()
end

function Troll:new(x, y, speed)
    local obj = {
        x = x,
        y = y,
        speed = speed
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Troll:reset(x, y, speed)
    self.x = x
    self.y = y
    self.speed = speed
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
end

function Troll:draw()
    love.graphics.setColor(1,1,1)
    love.graphics.draw(troll_canvas, self.x - TROLL_SIZE/2, self.y - TROLL_SIZE/2)
end

return Troll