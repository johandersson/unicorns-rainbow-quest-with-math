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

-- quiz_manager.lua
-- Manages math problems with progressive difficulty and variety
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
        -- Calculate difficulty progression (0.0 to 1.0)
        local progress = i / n_max
        local stage_equiv = math.floor(progress * 10) + 1  -- Simulate stages 1-10
        
        -- Determine problem type distribution
        local type_roll = math.random()
        
        if type_roll < 0.15 then
            -- 15% Number sequences (easy ones for variety)
            self:addSequenceProblem(stage_equiv)
        elseif type_roll < 0.20 and stage_equiv >= 4 then
            -- 5% Missing variable problems (X+a=c) for stages 4+
            self:addMissingVariableProblem(stage_equiv)
        elseif type_roll < 0.35 and stage_equiv >= 4 then
            -- 15% Subtraction for stages 4+
            self:addSubtractionProblem(stage_equiv)
        else
            -- Remaining: Addition problems
            self:addAdditionProblem(stage_equiv)
        end
    end
end

-- Simple number sequences like 1,3,5,7,?
function Quiz:addSequenceProblem(stage)
    local sequences = {
        -- Easy sequences (stages 1-3)
        {start=1, step=2, length=5},   -- 1,3,5,7,?=9
        {start=2, step=2, length=5},   -- 2,4,6,8,?=10
        {start=0, step=5, length=5},   -- 0,5,10,15,?=20
        {start=1, step=1, length=5},   -- 1,2,3,4,?=5
        -- Medium sequences (stages 4-6)
        {start=3, step=3, length=5},   -- 3,6,9,12,?=15
        {start=10, step=10, length=4}, -- 10,20,30,?=40
        {start=5, step=5, length=5},   -- 5,10,15,20,?=25
    }
    
    local seq_idx = stage <= 3 and math.random(1, 4) or math.random(1, #sequences)
    local seq = sequences[seq_idx]
    
    -- Build the sequence
    local nums = {}
    for i = 1, seq.length do
        table.insert(nums, seq.start + (i - 1) * seq.step)
    end
    
    local answer = nums[#nums]
    table.remove(nums) -- Remove last for the question
    
    -- Format as visual number line: _1_ _3_ _5_ _7_ _?_
    local question = ""
    for _, num in ipairs(nums) do
        question = question .. " " .. num .. " "
    end
    question = question .. " ?"
    
    table.insert(self.problems, {
        q = question,
        a = answer,
        type = 'sequence',
        visualType = 'numberline'
    })
end

-- Addition problems with difficulty scaling
function Quiz:addAdditionProblem(stage)
    local a, b
    
    if stage <= 2 then
        -- Stages 1-2: Mostly single digit (X + X)
        if math.random() < 0.8 then
            a = math.random(1, 9)
            b = math.random(1, 9)
        else
            a = math.random(1, 9)
            b = math.random(10, 15)
        end
    elseif stage <= 4 then
        -- Stages 3-4: Mix of single and small double digit
        if math.random() < 0.5 then
            a = math.random(1, 9)
            b = math.random(1, 9)
        else
            a = math.random(5, 15)
            b = math.random(5, 15)
        end
    else
        -- Stages 5+: Larger numbers
        local maxv = math.min(20 + (stage - 5) * 15, 80)
        a = math.random(1, maxv)
        b = math.random(1, maxv)
    end
    
    table.insert(self.problems, {
        q = string.format("%d + %d", a, b),
        a = a + b,
        type = 'addition'
    })
end

-- Subtraction problems (stage 4+)
function Quiz:addSubtractionProblem(stage)
    local a, b
    
    if stage <= 5 then
        -- Stages 4-5: Simple subtraction with positive results
        a = math.random(10, 25)
        b = math.random(1, a - 1)  -- Ensure positive result
    else
        -- Stages 6+: Can include negative results (harder!)
        a = math.random(5, 30)
        b = math.random(1, 40)  -- Can result in negative
    end
    
    table.insert(self.problems, {
        q = string.format("%d - %d", a, b),
        a = a - b,
        type = 'subtraction'
    })
end

-- Missing variable problems like X + 4 = 10 (stage 4+)
function Quiz:addMissingVariableProblem(stage)
    local x, a
    
    if stage <= 5 then
        x = math.random(1, 15)
        a = math.random(1, 10)
    else
        x = math.random(1, 25)
        a = math.random(5, 20)
    end
    
    local c = a + x
    
    table.insert(self.problems, {
        q = string.format("X + %d = %d", a, c),
        a = x,
        type = 'missing_variable'
    })
end

function Quiz:start()
    local pick = self.next_index
    if pick > #self.problems then pick = math.random(1, #self.problems) end
    local prob = self.problems[pick]
    self.game.quiz_problem = prob.q
    self.game.quiz_answer = prob.a
    self.game.quiz_type = prob.type
    self.game.quiz_visual_type = prob.visualType
    self.game.quiz_input = ""
    self.game.quiz_active = true
    self.game.stateManager.paused = true
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
            self.game.stateManager.paused = false
            self.game.unicorn = require('src.unicorn'):new(self.game.width / 2, self.game.height / 2, self.game.ground, self.game.width)
            -- after result, spawn a troll to resume challenge
            if self.game.trollManager then
                self.game.trollManager:add(math.random(0, self.game.width), -80, self.game.troll_base_speed)
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
