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

-- icon_renderer.lua
-- Renders cute icons as replacements for emojis that may not display correctly
local IconRenderer = {}
IconRenderer.__index = IconRenderer

-- Cache for rendered icons
local icon_cache = {}

function IconRenderer.new()
    local self = setmetatable({}, IconRenderer)
    self.icon_size = 16
    return self
end

-- Draw a small pink unicorn icon
function IconRenderer:drawUnicornIcon(x, y, size)
    size = size or self.icon_size
    local key = "unicorn_" .. size
    
    if not icon_cache[key] then
        icon_cache[key] = love.graphics.newCanvas(size, size)
        love.graphics.setCanvas(icon_cache[key])
        love.graphics.clear(0, 0, 0, 0)
        
        -- Body (pink oval)
        love.graphics.setColor(1, 0.75, 0.8)
        love.graphics.ellipse('fill', size * 0.5, size * 0.6, size * 0.3, size * 0.35)
        
        -- Head (smaller pink circle)
        love.graphics.setColor(1, 0.8, 0.85)
        love.graphics.circle('fill', size * 0.5, size * 0.35, size * 0.25)
        
        -- Horn (yellow triangle)
        love.graphics.setColor(1, 1, 0)
        love.graphics.polygon('fill', 
            size * 0.5, size * 0.05,
            size * 0.4, size * 0.3,
            size * 0.6, size * 0.3
        )
        
        -- Eye (small black dot)
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle('fill', size * 0.55, size * 0.35, size * 0.08)
        
        love.graphics.setCanvas()
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(icon_cache[key], x, y)
end

-- Draw medal icon (for high scores) - shiny with glow
function IconRenderer:drawMedalIcon(x, y, rank, size)
    size = size or self.icon_size
    
    -- Medal color based on rank
    local color, glow_color
    if rank == 1 then
        color = {1, 0.84, 0}  -- Gold
        glow_color = {1, 1, 0.3, 0.3}  -- Yellow glow
    elseif rank == 2 then
        color = {0.85, 0.85, 0.85}  -- Silver
        glow_color = {0.9, 0.9, 1, 0.3}  -- Silver glow
    else
        color = {0.85, 0.52, 0.25}  -- Bronze
        glow_color = {1, 0.6, 0.2, 0.3}  -- Orange glow
    end
    
    -- Draw outer glow
    love.graphics.setColor(glow_color)
    love.graphics.circle('fill', x + size * 0.5, y + size * 0.5, size * 0.55)
    
    -- Draw main medal circle
    love.graphics.setColor(color)
    love.graphics.circle('fill', x + size * 0.5, y + size * 0.5, size * 0.45)
    
    -- Inner darker ring for depth
    love.graphics.setColor(color[1] * 0.6, color[2] * 0.6, color[3] * 0.6)
    love.graphics.circle('fill', x + size * 0.5, y + size * 0.5, size * 0.35)
    
    -- Center white circle for number
    love.graphics.setColor(1, 1, 1, 0.95)
    love.graphics.circle('fill', x + size * 0.5, y + size * 0.5, size * 0.28)
    
    -- Shine/highlight at top-left
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.circle('fill', x + size * 0.35, y + size * 0.35, size * 0.15)
    
    -- Draw rank number centered
    love.graphics.setColor(0, 0, 0)
    local font = love.graphics.getFont()
    local old_font = font
    
    -- Use appropriate font size
    local font_size = math.max(8, math.floor(size * 0.5))
    local number_font = love.graphics.newFont(font_size)
    love.graphics.setFont(number_font)
    
    -- Center the number properly
    local text = tostring(rank)
    local text_width = number_font:getWidth(text)
    local text_height = number_font:getHeight()
    love.graphics.print(text, x + size * 0.5 - text_width * 0.5, y + size * 0.5 - text_height * 0.5)
    
    if old_font then
        love.graphics.setFont(old_font)
    end
end

-- Draw arrow icon (for scroll indicators and navigation)
function IconRenderer:drawArrowIcon(x, y, direction, size)
    size = size or self.icon_size
    local key = "arrow_" .. direction .. "_" .. size
    
    if not icon_cache[key] then
        icon_cache[key] = love.graphics.newCanvas(size, size)
        love.graphics.setCanvas(icon_cache[key])
        love.graphics.clear(0, 0, 0, 0)
        
        love.graphics.setColor(1, 1, 1)
        
        -- Draw triangle based on direction
        if direction == "up" then
            love.graphics.polygon('fill',
                size * 0.5, size * 0.2,
                size * 0.2, size * 0.8,
                size * 0.8, size * 0.8
            )
        elseif direction == "down" then
            love.graphics.polygon('fill',
                size * 0.2, size * 0.2,
                size * 0.8, size * 0.2,
                size * 0.5, size * 0.8
            )
        elseif direction == "left" then
            love.graphics.polygon('fill',
                size * 0.2, size * 0.5,
                size * 0.8, size * 0.2,
                size * 0.8, size * 0.8
            )
        elseif direction == "right" then
            love.graphics.polygon('fill',
                size * 0.2, size * 0.2,
                size * 0.8, size * 0.5,
                size * 0.2, size * 0.8
            )
        end
        
        love.graphics.setCanvas()
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(icon_cache[key], x, y)
end

-- Draw a star icon (for high score celebrations)
function IconRenderer:drawStarIcon(x, y, size)
    size = size or self.icon_size
    local key = "star_" .. size
    
    if not icon_cache[key] then
        icon_cache[key] = love.graphics.newCanvas(size, size)
        love.graphics.setCanvas(icon_cache[key])
        love.graphics.clear(0, 0, 0, 0)
        
        -- Draw 5-pointed star
        love.graphics.setColor(1, 1, 0) -- Yellow
        local points = {}
        local cx, cy = size * 0.5, size * 0.5
        local outerRadius = size * 0.45
        local innerRadius = size * 0.2
        
        for i = 0, 9 do
            local angle = (i * math.pi / 5) - math.pi / 2
            local radius = (i % 2 == 0) and outerRadius or innerRadius
            table.insert(points, cx + math.cos(angle) * radius)
            table.insert(points, cy + math.sin(angle) * radius)
        end
        
        love.graphics.polygon('fill', points)
        
        -- Inner glow
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.circle('fill', cx, cy, size * 0.1)
        
        love.graphics.setCanvas()
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(icon_cache[key], x, y)
end

return IconRenderer
