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

-- quiz_manager.lua
local Quiz = {}
Quiz.__index = Quiz

function Quiz:new(game)
    local obj = {
        game = game,
        problems = {},
        next_index = 1,
        time_limit = game.quiz_time_limit or 30,
        result_duration = game.quiz_result_duration or 1.5
    }
    setmetatable(obj, self)
    obj:generateProblems(game.problems_count or 1000)
    return obj
end

function Quiz:generateProblems(n)
    math.randomseed(os.time())
    local n_max = math.max(1, n)
    for i = 1, n do
        -- Pre-calculate fraction to avoid repeated division
        local frac = i / n_max
        local maxv = math.min(20 + math.floor(frac * 80), 100)
        maxv = math.max(10, maxv)
        
        local ptype_roll = math.random()
        if ptype_roll < 0.03 then
            local a = math.random(1, maxv)
            local x_max = math.min(20, maxv)
            local x = math.random(1, x_max)
            local c = a + x
            table.insert(self.problems, {q = string.format("%d + X = %d", a, c), a = x, type = 'missing'})
        else
            local a = math.random(1, maxv)
            local b_max = math.min(maxv, 100)
            local b = math.random(1, b_max)
            table.insert(self.problems, {q = string.format("%d + %d", a, b), a = a + b, type = 'normal'})
        end
    end
end

function Quiz:start()
    local pick = self.next_index
    if pick > #self.problems then pick = math.random(1, #self.problems) end
    local prob = self.problems[pick]
    self.game.quiz_problem = prob.q
    self.game.quiz_answer = prob.a
    self.game.quiz_input = ""
    self.game.quiz_active = true
    self.game.paused = true
    self.game.quiz_timer = self.time_limit
    self.next_index = pick + 1
end

function Quiz:update(dt)
    -- handle result timer
    if self.game.quiz_result_timer and self.game.quiz_result_timer > 0 then
        self.game.quiz_result_timer = self.game.quiz_result_timer - dt
        if self.game.quiz_result_timer <= 0 then
            self.game.quiz_result_timer = 0
            self.game.quiz_result_msg = nil
            self.game.quiz_active = false
            self.game.paused = false
            self.game.unicorn = require('src.unicorn'):new(self.game.width / 2, self.game.height / 2, self.game.ground, self.game.width)
            -- after result, spawn a troll to resume challenge
            if self.game.trollManager then
                self.game.trollManager:add(math.random(0, self.game.width), -10, self.game.troll_base_speed)
            end
        end
        return
    end
    if self.game.quiz_timer then
        self.game.quiz_timer = self.game.quiz_timer - dt
        if self.game.quiz_timer <= 0 then
            local msgs = (self.game.L and self.game.L.timeout_msgs) or {"Time! Try faster next time.", "Out of time!", "Too slow!"}
            self.game.quiz_result_msg = msgs[math.random(#msgs)]
            self.game.quiz_result_timer = self.result_duration
            -- leave quiz_active true so result clears later
        end
    end
end

return Quiz
