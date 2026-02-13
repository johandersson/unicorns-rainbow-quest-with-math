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
-- progression_system.lua
-- Manages stage progression, difficulty scaling, and extra lives
ProgressionSystem = {}

function ProgressionSystem:new()
    local obj = {
        stage = 1,
        coins = 100,
        sun_hits = 0,
        sun_hits_required = 3,
        coins_to_advance = 3,
        -- Extra life settings
        extra_life_base_cost = 250,
        extra_life_cost = 250,
        -- Troll difficulty
        troll_base_speed = 200,
        troll_spawn_interval = 4.0
    }
    
    setmetatable(obj, self)
    self.__index = self
    
    return obj
end

function ProgressionSystem:addCoins(amount)
    self.coins = self.coins + amount
end

function ProgressionSystem:deductCoins(amount)
    self.coins = self.coins - amount
end

function ProgressionSystem:getCoins()
    return self.coins
end

function ProgressionSystem:incrementSunHits()
    self.sun_hits = self.sun_hits + 1
end

function ProgressionSystem:canLevelUp(progress_coins)
    return self.sun_hits >= self.sun_hits_required and progress_coins >= self.coins_to_advance
end

function ProgressionSystem:needsMoreCoins(progress_coins)
    return self.sun_hits >= self.sun_hits_required and progress_coins < self.coins_to_advance
end

function ProgressionSystem:getRemainingCoins(progress_coins)
    return self.coins_to_advance - progress_coins
end

function ProgressionSystem:checkExtraLives()
    if self.coins >= self.extra_life_cost then
        local lives_to_add = math.floor(self.coins / self.extra_life_cost)
        lives_to_add = math.min(lives_to_add, 100) -- Guard against absurd numbers
        self.coins = self.coins - lives_to_add * self.extra_life_cost
        return lives_to_add
    end
    return 0
end

function ProgressionSystem:levelUp()
    self.sun_hits = 0
    self.stage = self.stage + 1
    
    -- Increase difficulty
    self.troll_base_speed = self.troll_base_speed + 20
    self.troll_spawn_interval = math.max(1.0, self.troll_spawn_interval - 0.25)
    
    -- Increase requirements
    self.sun_hits_required = math.ceil(3 + (self.stage - 1) * 0.75)
    self.coins_to_advance = 3 + math.floor(self.stage / 3)
    
    -- Make extra lives more expensive
    self.extra_life_cost = self.extra_life_base_cost + (self.stage - 1) * 75
    
    -- Return spawn count for new trolls
    return math.min(1 + math.floor(self.stage / 2), 6)
end

function ProgressionSystem:getTrollSpawnCount()
    -- Gradually increase spawn count and probability as stage advances
    local base = 1
    local extra = math.floor((self.stage - 1) / 3) -- +1 every 3 stages
    local max_spawn = math.min(base + extra, 4)
    local prob_more = math.min(0.25 + self.stage * 0.03, 0.9)
    if math.random() < prob_more then
        return math.random(1, max_spawn)
    end
    return 1
end

function ProgressionSystem:getTrollSpeed()
    return self.troll_base_speed + math.random(-30, 60)
end

function ProgressionSystem:reset()
    self.stage = 1
    self.coins = 100
    self.sun_hits = 0
    self.sun_hits_required = 3
    self.coins_to_advance = 3
    self.extra_life_cost = self.extra_life_base_cost
    self.troll_base_speed = 200
    self.troll_spawn_interval = 4.0
end

return ProgressionSystem
