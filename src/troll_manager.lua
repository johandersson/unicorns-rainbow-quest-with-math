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
        spawn_interval = game.troll_spawn_interval or 4.0,
        troll_sound_cooldown = 0  -- Prevent sound spam
    }
    setmetatable(obj, self)
    return obj
end

function TrollManager:add(x, y, speed)
    -- Ensure speed has a valid value
    local troll_speed = speed or self.base_speed or 200
    
    local troll
    if #self.pool > 0 then
        troll = table.remove(self.pool)
        troll:reset(x, y, troll_speed)
    else
        troll = Troll:new(x, y, troll_speed)
    end
    troll.target = self.game.unicorn
    table.insert(self.trolls, {troll = troll, active = true})
end

function TrollManager:update(dt)
    -- Update sound cooldown
    if self.troll_sound_cooldown > 0 then
        self.troll_sound_cooldown = self.troll_sound_cooldown - dt
    end
    
    -- Check for close trolls to play warning sound
    local closest_dist_sq = math.huge
    for _, entry in ipairs(self.trolls) do
        if entry.active then
            local t = entry.troll
            local dx = self.game.unicorn.x - t.x
            local dy = self.game.unicorn.y - t.y
            local dist_sq = dx*dx + dy*dy
            if dist_sq < closest_dist_sq then
                closest_dist_sq = dist_sq
            end
        end
    end
    
    -- Play warning sound if a troll is close but not colliding
    local warning_radius_sq = 150 * 150  -- 22500
    local collision_radius_sq = 45 * 45   -- 2025 (increased from 28 to catch fast-moving trolls)
    if closest_dist_sq < warning_radius_sq and closest_dist_sq > collision_radius_sq and self.troll_sound_cooldown <= 0 then
        if self.game.soundManager then
            self.game.soundManager:play('troll')
            self.troll_sound_cooldown = 1.5  -- Play sound max once every 1.5 seconds
        end
    end
    
    local i = 1
    while i <= #self.trolls do
        local entry = self.trolls[i]
        local t = entry.troll
        if entry.active then
            t:update(dt, self.game.unicorn)
            -- Collision detection with buffer for fast-moving trolls
            -- Troll visual radius ~25px, unicorn ~25px
            local dx = self.game.unicorn.x - t.x
            local dy = self.game.unicorn.y - t.y
            -- Collision radius: 45 pixels - accounts for sprite sizes + movement speed
            -- Prevents trolls from "jumping through" unicorn at high speeds
            local collision_radius_sq = 45 * 45  -- 2025
            if dx*dx + dy*dy < collision_radius_sq then
                table.insert(self.pool, t)
                self.trolls[i] = self.trolls[#self.trolls]
                table.remove(self.trolls)
                
                -- Play death sound
                if self.game.soundManager then
                    self.game.soundManager:play('death')
                end
                
                -- Update lives through stateManager
                self.game.stateManager.lives = self.game.stateManager.lives - 1
                self.game.stateManager.lives = math.max(0, math.floor(self.game.stateManager.lives))
                
                if self.game.stateManager.lives <= 0 then
                    self.game.stateManager.game_over = true
                else
                    self.game.stateManager.paused = true
                    self.game.stateManager.death_timer = 0
                    self.game.stateManager.flash_alpha = 1
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
            self:add(sx, -80, speed)
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
