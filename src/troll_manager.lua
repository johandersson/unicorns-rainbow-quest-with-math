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
-- troll_manager.lua
local Troll = require('src.troll')

local TrollManager = {}
TrollManager.__index = TrollManager

function TrollManager:new(game)
    local obj = {
        game = game,
        trolls = {},
        pool = {},
        base_speed = game.troll_base_speed or 200,
        spawn_timer = 0,
        spawn_interval = game.troll_spawn_interval or 4.0
    }
    setmetatable(obj, self)
    return obj
end

function TrollManager:add(x, y, speed)
    local troll
    if #self.pool > 0 then
        troll = table.remove(self.pool)
        troll:reset(x, y, speed)
    else
        troll = Troll:new(x, y, speed)
    end
    troll.target = self.game.unicorn
    table.insert(self.trolls, {troll = troll, active = true})
end

function TrollManager:update(dt)
    local i = 1
    while i <= #self.trolls do
        local entry = self.trolls[i]
        local t = entry.troll
        if entry.active then
            t:update(dt, self.game.unicorn)
            -- Tighter collision detection - only register hits when truly touching
            -- Troll visual radius is 20px, unicorn is ~20px, require actual overlap
            local dx = self.game.unicorn.x - t.x
            local dy = self.game.unicorn.y - t.y
            -- Reduced collision radius: only ~28 pixels (troll 20 + unicorn 15 - 7 overlap tolerance)
            -- This prevents "phantom hits" from far away
            local collision_radius_sq = 28 * 28  -- 784 (was 1600 = 40^2)
            if dx*dx + dy*dy < collision_radius_sq then
                table.insert(self.pool, t)
                self.trolls[i] = self.trolls[#self.trolls]
                table.remove(self.trolls)
                self.game.lives = (self.game.lives or 0) - 1
                -- clamp and ensure integer
                self.game.lives = math.max(0, math.floor(self.game.lives))
                if self.game.lives <= 0 then
                    self.game.game_over = true
                else
                    self.game.paused = true
                    self.game.death_timer = 0
                    self.game.flash_alpha = 1
                end
                break
            end
            if t.y > self.game.height + 50 then
                table.insert(self.pool, t)
                self.trolls[i] = self.trolls[#self.trolls]
                table.remove(self.trolls)
            else
                i = i + 1
            end
        else
            self.trolls[i] = self.trolls[#self.trolls]
            table.remove(self.trolls)
        end
    end
    -- optional periodic spawn scaled by game.progressionSystem.stage
    self.spawn_timer = self.spawn_timer + dt
    if self.spawn_timer >= self.spawn_interval then
        self.spawn_timer = self.spawn_timer - self.spawn_interval
        local stage = self.game.progressionSystem and self.game.progressionSystem.stage or 1
        local count = (math.random() < math.min(0.25 + stage * 0.05, 0.8)) and 1 or 0
        for j = 1, count do
            local sx = math.random(0, self.game.width)
            local speed = self.base_speed + math.random(-30, 60)
            self:add(sx, -10, speed)
        end
    end
end

function TrollManager:draw()
    for _, entry in ipairs(self.trolls) do
        if entry.active then
            entry.troll:draw()
        end
    end
end

return TrollManager
