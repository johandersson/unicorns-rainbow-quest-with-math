--[[
  Rainbow Quest - Unicorn Flight
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
-- background_renderer.lua
-- Responsible for rendering the static background (rainbow, sun, ground, flowers)
BackgroundRenderer = {}

-- Pre-calculated rainbow colors at module level
local RAINBOW_COLORS = {
    {1, 0, 0},     -- red
    {1, 0.5, 0},   -- orange
    {1, 1, 0},     -- yellow
    {0, 1, 0},     -- green
    {0, 0, 1},     -- blue
    {0.3, 0, 0.5}, -- indigo
    {0.5, 0, 0.5}  -- violet
}

function BackgroundRenderer:new(width, height, sun_x, sun_y, ground)
    local obj = {
        width = width,
        height = height,
        sun_x = sun_x,
        sun_y = sun_y,
        ground = ground,
        canvas = nil
    }
    
    setmetatable(obj, self)
    self.__index = self
    
    obj:regenerateCanvas()
    
    return obj
end

function BackgroundRenderer:regenerateCanvas()
    self.canvas = love.graphics.newCanvas(self.width, self.height)
    love.graphics.setCanvas(self.canvas)
    
    -- Draw rainbow background
    for i = 1, 7 do
        love.graphics.setColor(unpack(RAINBOW_COLORS[i]))
        love.graphics.arc('fill', self.width / 2, self.height, (8 - i) * 50, math.pi, 2 * math.pi)
    end
    
    -- Draw sun
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle('fill', self.sun_x, self.sun_y, 40)
    
    -- Draw ground
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.rectangle('fill', 0, self.ground, self.width, 50)
    
    -- Draw flowers
    self:drawFlowers()
    
    love.graphics.setCanvas() -- back to default
end

function BackgroundRenderer:drawFlowers()
    -- Green stems
    love.graphics.setColor(0, 0.5, 0)
    for i = 1, 3 do
        local x = self.width * (i / 4)
        love.graphics.line(x, self.ground, x, self.ground - 20)
    end
    
    -- Red petals
    love.graphics.setColor(1, 0, 0)
    for i = 1, 3 do
        local x = self.width * (i / 4)
        love.graphics.circle('fill', x, self.ground - 20, 5)
        love.graphics.circle('fill', x - 5, self.ground - 25, 5)
        love.graphics.circle('fill', x + 5, self.ground - 25, 5)
    end
    
    -- Yellow centers
    love.graphics.setColor(1, 1, 0)
    for i = 1, 3 do
        local x = self.width * (i / 4)
        love.graphics.circle('fill', x, self.ground - 20, 2)
    end
end

function BackgroundRenderer:draw()
    love.graphics.draw(self.canvas, 0, 0)
end

function BackgroundRenderer:resize(w, h, sun_x, ground)
    self.width = w
    self.height = h
    self.sun_x = sun_x
    self.ground = ground
    self:regenerateCanvas()
end

return BackgroundRenderer
