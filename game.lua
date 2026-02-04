-- game.lua
Game = {}

-- Pre-calculated constants (memoization at module level for O(1) access)
local RAINBOW_COLORS = {
    {1, 0, 0},     -- red
    {1, 0.5, 0},   -- orange
    {1, 1, 0},     -- yellow
    {0, 1, 0},     -- green
    {0, 0, 1},     -- blue
    {0.3, 0, 0.5}, -- indigo
    {0.5, 0, 0.5}  -- violet
}

function Game:new()
    local obj = {
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight(),
        unicorn = nil,
        coins = 100,
        game_over = false,
        ground = 0,
        stage = 1,
        sun_x = 0,
        sun_y = 50,
        lives = 3,
        trolls = {},
        troll_pool = {},
        paused = false,
        death_timer = 0,
        respawn_delay = 1.2,
        flash_alpha = 0,
        -- Extra life settings (starts easy, gets progressively harder)
        extra_life_base_cost = 250,
        extra_life_cost = 250,
        extra_life_msg = nil,
        extra_life_msg_timer = 0,
        extra_life_msg_duration = 1.5,
        -- Pre-created fonts to avoid per-frame allocations (smaller for status)
        font_large = love.graphics.newFont(20),
        -- make status font larger for readability
        font_small = love.graphics.newFont(14)
        ,
        -- Quiz / math problem fields
        quiz_active = false,
        quiz_input = "",
        quiz_problem = nil,
        quiz_answer = nil,
        quiz_result_msg = nil,
        quiz_result_timer = 0,
        quiz_result_duration = 1.5,
        quiz_time_limit = 30,
        quiz_show_answer = false,
        quiz_correct_answer = nil,
        problems_file = 'math_problems.txt',
        problems_count = 10000,
        -- Memoization cache for formatted strings (avoid O(n) string operations per frame)
        _cached_strings = {},
        _string_cache_frame = 0,
        -- progression and spawn tuning
        sun_hits = 0,
        -- make it harder: require multiple sun visits before stage-up
        sun_hits_required = 3,
        troll_spawn_timer = 0,
        troll_spawn_interval = 4.0,
        troll_base_speed = 200,
        -- collectible coins that must be gathered to advance
        field_coins = {},
        coin_pool = {},
        coin_spawn_timer = 0,
        coin_spawn_interval = 12.0,
        coin_lifetime = 30.0,  -- Increased lifetime so coins stay longer
        coin_radius = 18,
        coins_to_advance = 3,
        progress_coins = 0,
        -- manual pause toggle (pause everything until 'p' pressed again)
        manual_pause = false,
        -- show welcome screen at launch until player confirms
        show_welcome = true,
        -- quiz/problem configuration
        problems = {},
        next_problem_index = 1
    }
    obj.ground = obj.height - 50
    obj.sun_x = obj.width / 2

        -- Create background canvas
        obj.background_canvas = love.graphics.newCanvas(obj.width, obj.height)
        love.graphics.setCanvas(obj.background_canvas)

    -- Draw rainbow background
    for i = 1, 7 do
        love.graphics.setColor(unpack(RAINBOW_COLORS[i]))
        love.graphics.arc('fill', obj.width / 2, obj.height, (8 - i) * 50, math.pi, 2 * math.pi)
    end

    

    -- Draw sun
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle('fill', obj.sun_x, obj.sun_y, 40)

    -- Draw ground
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.rectangle('fill', 0, obj.ground, obj.width, 50)

    -- Draw flowers
    love.graphics.setColor(0, 0.5, 0) -- green stems
    for i = 1, 3 do
        local x = obj.width * (i / 4)
        love.graphics.line(x, obj.ground, x, obj.ground - 20)
    end
    love.graphics.setColor(1, 0, 0) -- red petals
    for i = 1, 3 do
        local x = obj.width * (i / 4)
        love.graphics.circle('fill', x, obj.ground - 20, 5)
        love.graphics.circle('fill', x - 5, obj.ground - 25, 5)
        love.graphics.circle('fill', x + 5, obj.ground - 25, 5)
    end
    love.graphics.setColor(1, 1, 0) -- yellow centers
    for i = 1, 3 do
        local x = obj.width * (i / 4)
        love.graphics.circle('fill', x, obj.ground - 20, 2)
    end

    love.graphics.setCanvas() -- back to default

    obj.unicorn = require('unicorn'):new(obj.width / 2, obj.height / 2, obj.ground, obj.width)
    setmetatable(obj, self)
    self.__index = self
    obj:addTroll(math.random(0, obj.width), -10, 200)

    -- attach managers
    obj.trollManager = require('troll_manager'):new(obj)
    obj.quizManager = require('quiz_manager'):new(obj)
    -- load Swedish locale by default
    obj.L = require('locales.sv')
    
    -- Cache frequently used locale strings (memoization to avoid O(n) table lookups per frame)
    obj._locale_cache = {
        coins_label = obj.L.coins_label or "Coins: %d",
        stage_label = obj.L.stage_label or "Stage: %d (need: %d)",
        lives_label = obj.L.lives_label or "Lives: %d",
        progress_label = obj.L.progress_label or "Progress: %d/%d",
        game_over = obj.L.game_over or "Game Over! Press R to restart",
        you_died = obj.L.you_died or "You died! Lives left: %d",
        respawning = obj.L.respawning or "Respawning...",
        quiz_title = obj.L.quiz_title or "Math Challenge!",
        time_label = obj.L.time_label or "Time: %ds",
        quiz_hint = obj.L.quiz_hint or "Type the answer and press Enter. +100 coins for correct.",
        correct_answer_label = obj.L.correct_answer_label or "The correct answer was:"
    }

    return obj
end

-- Memoization helper for formatted strings (cache per-frame to avoid redundant string.format)
function Game:cachedFormat(key, template, ...)
    -- Simple frame-based cache invalidation
    local args = {...}
    local cache_key = key .. table.concat(args, "|")
    
    if not self._cached_strings[cache_key] then
        self._cached_strings[cache_key] = template:format(...)
    end
    
    return self._cached_strings[cache_key]
end

-- Retro-style dialog box with shadow (not transparent)
function Game:drawRetroDialog(x, y, w, h, border_color, bg_color)
    border_color = border_color or {1, 1, 1}
    bg_color = bg_color or {0.1, 0.1, 0.2}
    
    -- Shadow (offset down-right)
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle('fill', x + 4, y + 4, w, h)
    
    -- Background
    love.graphics.setColor(bg_color[1], bg_color[2], bg_color[3])
    love.graphics.rectangle('fill', x, y, w, h)
    
    -- Outer border (thick retro style)
    love.graphics.setColor(border_color[1], border_color[2], border_color[3])
    love.graphics.setLineWidth(3)
    love.graphics.rectangle('line', x, y, w, h)
    
    -- Inner border for double-line effect
    love.graphics.setLineWidth(1)
    love.graphics.rectangle('line', x + 6, y + 6, w - 12, h - 12)
    
    love.graphics.setLineWidth(1) -- reset
end

function Game:addTroll(x, y, speed)
    -- Prefer manager if available
    if self.trollManager then
        self.trollManager:add(x, y, speed)
        return
    end
    local troll
    if #self.troll_pool > 0 then
        troll = table.remove(self.troll_pool)
        troll:reset(x, y, speed)
    else
        troll = require('troll'):new(x, y, speed)
    end
    troll.target = self.unicorn
    table.insert(self.trolls, {troll = troll, active = true})
end

-- troll update handled inline in Game:update (swap-remove loop)

function Game:spawnFieldCoin()
    local cx = math.random(40, self.width - 40)
    -- place coins above the rainbow / in the upper play area so they're easier to catch
    local upper_max = math.max(60, math.floor(self.height * 0.35))
    local cy = math.random(30, upper_max)
    local Coin = require('coin')
    local coin
    if #self.coin_pool > 0 then
        coin = table.remove(self.coin_pool)
        coin:reset(cx, cy, self.coin_lifetime, self.coin_radius)
    else
        coin = Coin:new(cx, cy, self.coin_lifetime, self.coin_radius)
    end
    table.insert(self.field_coins, coin)
end

function Game:updateFieldCoins(dt)
    -- spawn
    self.coin_spawn_timer = (self.coin_spawn_timer or 0) + dt
    if self.coin_spawn_timer >= self.coin_spawn_interval then
        self.coin_spawn_timer = self.coin_spawn_timer - self.coin_spawn_interval
        self:spawnFieldCoin()
    end

    -- update and collect using swap-remove
    local k = 1
    while k <= #self.field_coins do
        local fc = self.field_coins[k]
        fc:update(dt)
        local collected = false
        if fc.t > 0 then
            if fc:isCollectedBy(self.unicorn) then
                collected = true
            end
        end
        if collected then
            self.progress_coins = self.progress_coins + 1
            self.coins = self.coins + 10
            self.extra_life_msg = "+10 coins"
            self.extra_life_msg_timer = 1.2
            -- recycle coin
            table.insert(self.coin_pool, fc)
            self.field_coins[k] = self.field_coins[#self.field_coins]
            table.remove(self.field_coins)
        elseif fc.t <= 0 then
            -- expired, recycle
            table.insert(self.coin_pool, fc)
            self.field_coins[k] = self.field_coins[#self.field_coins]
            table.remove(self.field_coins)
        else
            k = k + 1
        end
    end
end


function Game:update(dt)
    if self.game_over then return end

    -- global manual pause: halt all gameplay updates until toggled off
    if self.manual_pause then return end

    -- welcome screen blocks gameplay until player confirms
    if self.show_welcome then return end

    -- If a quiz is active, delegate timing and results to the quiz manager
    if self.quiz_active then
        if self.quizManager then self.quizManager:update(dt) end
        return
    end

    local hit_ground = self.unicorn:update(dt)
    if hit_ground then
        self.lives = (self.lives or 0) - 1
        self.lives = math.max(0, math.floor(self.lives))
        if self.lives <= 0 then
            self.game_over = true
            return
        else
            -- pause and show death message, then respawn after delay
            self.paused = true
            self.death_timer = 0
            self.flash_alpha = 1
        end
    end

    -- If paused due to death, advance death timer and respawn when ready
    if self.paused then
        self.death_timer = self.death_timer + dt
        self.flash_alpha = math.max(0, 1 - (self.death_timer / self.respawn_delay))
        if self.death_timer >= self.respawn_delay then
            self.paused = false
            -- respawn unicorn
            self.unicorn = require('unicorn'):new(self.width / 2, self.height / 2, self.ground, self.width)
            -- update troll targets to the new unicorn
            for _, entry in ipairs(self.trolls) do
                entry.troll.target = self.unicorn
                entry.active = true
            end
        end
        return
    end

    -- update extra life message timer
    if self.extra_life_msg_timer and self.extra_life_msg_timer > 0 then
        self.extra_life_msg_timer = self.extra_life_msg_timer - dt
        if self.extra_life_msg_timer <= 0 then
            self.extra_life_msg = nil
            self.extra_life_msg_timer = 0
        end
    end

    

    -- Update trolls via manager if present
    if self.trollManager then
        self.trollManager:update(dt)
    else
        -- fallback: update inline troll list
        local i = 1
        while i <= #self.trolls do
            local entry = self.trolls[i]
            local t = entry.troll
            if entry.active then
                t:update(dt, self.unicorn)
                -- collision with unicorn
                if math.abs(self.unicorn.x - t.x) < 40 and math.abs(self.unicorn.y - t.y) < 40 then
                    -- recycle troll into pool
                    table.insert(self.troll_pool, t)
                    -- swap-remove current entry
                    self.trolls[i] = self.trolls[#self.trolls]
                    table.remove(self.trolls)
                    -- handle lives and start death pause
                    self.lives = self.lives - 1
                    if self.lives <= 0 then
                        self.game_over = true
                    else
                        self.paused = true
                        self.death_timer = 0
                        self.flash_alpha = 1
                    end
                    break
                end

                -- recycle trolls that fall off bottom
                if t.y > self.height + 50 then
                    table.insert(self.troll_pool, t)
                    self.trolls[i] = self.trolls[#self.trolls]
                    table.remove(self.trolls)
                else
                    i = i + 1
                end
            else
                -- remove any inactive entries defensively
                self.trolls[i] = self.trolls[#self.trolls]
                table.remove(self.trolls)
            end
        end
    end

    -- Check if reached the sun (sun hits required to level up)
    if self.unicorn.y < self.sun_y + 40 and math.abs(self.unicorn.x - self.sun_x) < 40 then
        -- Small reward per sun hit (reduced to prevent easy coin farming)
        self.coins = self.coins + 3
        self.sun_hits = self.sun_hits + 1

        -- award extra lives if coins exceed threshold (compute in one step)
        if self.coins >= self.extra_life_cost then
            local add = math.floor(self.coins / self.extra_life_cost)
            -- guard against absurd numbers
            add = math.min(add, 100)
            self.coins = self.coins - add * self.extra_life_cost
            self.lives = (self.lives or 0) + add
            local lm = (self.L and self.L.gain_lives) or "+%d lives"
            self.extra_life_msg = lm:format(add)
            self.extra_life_msg_timer = self.extra_life_msg_duration
        end

        -- If we've reached the required number of sun visits AND collected enough field coins, level up
        if self.sun_hits >= self.sun_hits_required and self.progress_coins >= self.coins_to_advance then
            self.sun_hits = 0
            self.progress_coins = 0
            self.stage = self.stage + 1
            -- increase difficulty: increase base speed and reduce spawn interval slightly
            self.troll_base_speed = self.troll_base_speed + 20
            self.troll_spawn_interval = math.max(1.0, self.troll_spawn_interval - 0.25)
            -- increase next requirement progressively
            self.sun_hits_required = math.ceil(3 + (self.stage - 1) * 0.75)
            self.coins_to_advance = 3 + math.floor(self.stage / 3)
            
            -- Make extra lives progressively more expensive (increases 75 coins per stage)
            self.extra_life_cost = self.extra_life_base_cost + (self.stage - 1) * 75

            -- spawn a few trolls to mark the new stage
            local spawn_count = math.min(1 + math.floor(self.stage / 2), 6)
            for i = 1, spawn_count do
                local sx = math.random(0, self.width)
                local speed = self.troll_base_speed + math.random(-20, 40)
                self:addTroll(sx, -10, speed)
            end

            -- delegate quiz start to quiz manager
            self.paused = true
            if self.quizManager then
                self.quizManager:start()
            else
                -- fallback: enable quiz state minimally
                self.quiz_active = true
                self.quiz_input = ""
                self.quiz_timer = self.quiz_time_limit
            end
        elseif self.sun_hits >= self.sun_hits_required then
            -- Not enough field coins yet; encourage player to collect more
            local msgfmt = (self.L and self.L.collect_more) or "Collect %d more coins to level up"
            self.extra_life_msg = msgfmt:format(self.coins_to_advance - self.progress_coins)
            self.extra_life_msg_timer = 2.0
        end
        -- do not spawn new troll/unicorn until quiz finished
    end

    -- periodic troll spawning to increase pressure
    self.troll_spawn_timer = self.troll_spawn_timer + dt
    if self.troll_spawn_timer >= self.troll_spawn_interval then
        self.troll_spawn_timer = self.troll_spawn_timer - self.troll_spawn_interval
        -- spawn 0..1 extra troll(s) scaled by stage
        local count = (math.random() < math.min(0.25 + self.stage * 0.05, 0.8)) and 1 or 0
        for i = 1, count do
            local sx = math.random(0, self.width)
            local speed = self.troll_base_speed + math.random(-30, 60)
            self:addTroll(sx, -10, speed)
        end
    end

    -- Update field coins (spawning, lifetimes, collection)
    self:updateFieldCoins(dt)
end

function Game:draw()
    -- Draw background canvas
    love.graphics.draw(self.background_canvas, 0, 0)

    -- Draw trolls via manager if present
    if self.trollManager then
        self.trollManager:draw()
    else
        for _, entry in ipairs(self.trolls) do
            if entry.active then
                entry.troll:draw()
            end
        end
    end

    -- Draw static collectible coins (behind the unicorn so unicorn appears on top)
    for _, fc in ipairs(self.field_coins) do
        if type(fc.draw) == 'function' then
            fc:draw()
        else
            -- fallback for plain tables
            love.graphics.setColor(1, 0.85, 0)
            love.graphics.circle('fill', fc.x, fc.y, self.coin_radius)
            love.graphics.setColor(1, 1, 0.6)
            love.graphics.circle('fill', fc.x - 4, fc.y - 4, self.coin_radius * 0.5)
            love.graphics.setColor(0.8, 0.6, 0)
            love.graphics.circle('line', fc.x, fc.y, self.coin_radius)
        end
    end

    -- Draw unicorn on top of coins
    self.unicorn:draw()

    -- Draw UI (use smaller font for status to avoid large text)
    love.graphics.setFont(self.font_small)
    -- small shadow for contrast: draw black offset then white text
    local function shadowed_print(text, x, y)
        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.print(text, x + 1, y + 1)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(text, x, y)
    end
    -- Use cached formatting to avoid repeated string.format (memoization)
    shadowed_print(self:cachedFormat("coins", self._locale_cache.coins_label, self.coins), 10, 10)
    shadowed_print(self:cachedFormat("stage", self._locale_cache.stage_label, self.stage, self.sun_hits_required), 10, 26)
    shadowed_print(self:cachedFormat("lives", self._locale_cache.lives_label, self.lives), 10, 42)
    shadowed_print(self:cachedFormat("progress", self._locale_cache.progress_label, self.progress_coins, self.coins_to_advance), 10, 58)

    -- Draw game over
    if self.game_over then
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf(self._locale_cache.game_over, 0, self.height / 2, self.width, 'center')
    end

    -- Death flash / message when paused
    if self.paused and not self.game_over then
        -- semi-transparent overlay
        love.graphics.setColor(0, 0, 0, 0.4 * self.flash_alpha)
        love.graphics.rectangle('fill', 0, 0, self.width, self.height)

        love.graphics.setColor(1, 1, 1)
        local msg = self._locale_cache.you_died:format(self.lives)
        love.graphics.setFont(self.font_large)
        love.graphics.printf(msg, 0, self.height / 2 - 20, self.width, 'center')

        love.graphics.setFont(self.font_small)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(self._locale_cache.respawning, 0, self.height / 2 + 20, self.width, 'center')
    end

    -- Extra life message (top-right so it doesn't clash with center messages)
    if self.extra_life_msg_timer and self.extra_life_msg_timer > 0 then
        love.graphics.setFont(self.font_large)
        love.graphics.setColor(1, 1, 0)
        local msgw = 220
        love.graphics.printf(self.extra_life_msg or "", self.width - msgw - 10, 10, msgw, 'right')
    end

    -- Quiz overlay - retro dialog style
    if self.quiz_active then
        -- Dim background (not completely transparent)
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle('fill', 0, 0, self.width, self.height)

        -- Main dialog box
        local dialog_w = math.min(500, self.width - 60)
        local dialog_h = 220
        local dialog_x = (self.width - dialog_w) / 2
        local dialog_y = (self.height - dialog_h) / 2 - 30
        
        self:drawRetroDialog(dialog_x, dialog_y, dialog_w, dialog_h, {0.3, 0.7, 1}, {0.05, 0.05, 0.15})
        
        -- Title
        love.graphics.setFont(self.font_large)
        love.graphics.setColor(1, 1, 0.3)
        love.graphics.printf(self._locale_cache.quiz_title, dialog_x, dialog_y + 20, dialog_w, 'center')

        -- Problem text
        love.graphics.setFont(self.font_large)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(self.quiz_problem or "", dialog_x, dialog_y + 60, dialog_w, 'center')

        -- Timer
        if self.quiz_timer then
            love.graphics.setFont(self.font_small)
            love.graphics.setColor(1, 0.8, 0.4)
            love.graphics.printf(self._locale_cache.time_label:format(math.ceil(self.quiz_timer)), dialog_x, dialog_y + 100, dialog_w, 'center')
        end

        -- Input box (retro style)
        local input_w = 260
        local input_h = 36
        local input_x = dialog_x + (dialog_w - input_w) / 2
        local input_y = dialog_y + 125
        
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle('fill', input_x, input_y, input_w, input_h)
        love.graphics.setColor(0.3, 0.7, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle('line', input_x, input_y, input_w, input_h)
        love.graphics.setLineWidth(1)
        
        love.graphics.setFont(self.font_large)
        love.graphics.setColor(0, 1, 0)
        love.graphics.printf(self.quiz_input .. "_", input_x + 8, input_y + 6, input_w - 16, 'center')

        -- Hint
        love.graphics.setFont(self.font_small)
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.printf(self._locale_cache.quiz_hint, dialog_x, dialog_y + 175, dialog_w, 'center')
    end

    -- Quiz result message - retro dialog box
    if self.quiz_result_timer and self.quiz_result_timer > 0 then
        -- Dim background slightly
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.rectangle('fill', 0, 0, self.width, self.height)
        
        -- Result dialog box
        local result_w = math.min(450, self.width - 80)
        local result_h = self.quiz_show_answer and 180 or 140
        local result_x = (self.width - result_w) / 2
        local result_y = (self.height - result_h) / 2
        
        -- Color based on success/failure
        local border_color = self.quiz_show_answer and {1, 0.3, 0.3} or {0.3, 1, 0.3}
        local bg_color = self.quiz_show_answer and {0.15, 0.05, 0.05} or {0.05, 0.15, 0.05}
        
        self:drawRetroDialog(result_x, result_y, result_w, result_h, border_color, bg_color)
        
        -- Result message
        love.graphics.setFont(self.font_large)
        local msg_color = self.quiz_show_answer and {1, 0.5, 0.5} or {0.5, 1, 0.5}
        love.graphics.setColor(msg_color[1], msg_color[2], msg_color[3])
        love.graphics.printf(self.quiz_result_msg or "", result_x, result_y + 30, result_w, 'center')
        
        -- Show correct answer if wrong
        if self.quiz_show_answer and self.quiz_correct_answer then
            love.graphics.setFont(self.font_small)
            love.graphics.setColor(1, 1, 0.6)
            love.graphics.printf(self._locale_cache.correct_answer_label, result_x, result_y + 80, result_w, 'center')
            
            love.graphics.setFont(self.font_large)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(tostring(self.quiz_correct_answer), result_x, result_y + 110, result_w, 'center')
        end
    end

    -- Manual pause overlay (draw on top if active)
    if self.manual_pause then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle('fill', 0, 0, self.width, self.height)
        love.graphics.setFont(self.font_large)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Paused - press P to resume", 0, self.height/2 - 20, self.width, 'center')
    end

    -- Welcome screen overlay (blocks start until confirmed)
    if self.show_welcome then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle('fill', 0, 0, self.width, self.height)
        love.graphics.setFont(self.font_large)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Welcome to Rainbow Quest!", 0, self.height/2 - 80, self.width, 'center')
        love.graphics.setFont(self.font_small)
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.printf("Collect coins, reach the sun, and solve math challenges.", 0, self.height/2 - 40, self.width, 'center')
        love.graphics.printf("Controls: Arrow keys to move, Up to fly, P to pause.", 0, self.height/2 - 10, self.width, 'center')
        love.graphics.setColor(1, 1, 0)
        love.graphics.printf("Press Enter or Space to Start", 0, self.height/2 + 30, self.width, 'center')
    end
end

function Game:resize(w, h)
    self.width = w
    self.height = h
    self.ground = h - 50
    self.sun_x = w / 2

    -- Recreate background canvas
    self.background_canvas = love.graphics.newCanvas(w, h)
    love.graphics.setCanvas(self.background_canvas)

    -- Draw rainbow background
    for i = 1, 7 do
        love.graphics.setColor(unpack(RAINBOW_COLORS[i]))
        love.graphics.arc('fill', w / 2, h, (8 - i) * 50, math.pi, 2 * math.pi)
    end

    -- Draw sun
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle('fill', self.sun_x, self.sun_y, 40)

    -- Draw ground
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.rectangle('fill', 0, self.ground, w, 50)

    -- Draw flowers
    love.graphics.setColor(0, 0.5, 0) -- green stems
    for i = 1, 3 do
        local x = w * (i / 4)
        love.graphics.line(x, self.ground, x, self.ground - 20)
    end
    love.graphics.setColor(1, 0, 0) -- red petals
    for i = 1, 3 do
        local x = w * (i / 4)
        love.graphics.circle('fill', x, self.ground - 20, 5)
        love.graphics.circle('fill', x - 5, self.ground - 25, 5)
        love.graphics.circle('fill', x + 5, self.ground - 25, 5)
    end
    love.graphics.setColor(1, 1, 0) -- yellow centers
    for i = 1, 3 do
        local x = w * (i / 4)
        love.graphics.circle('fill', x, self.ground - 20, 2)
    end

    love.graphics.setCanvas() -- back to default
end

function Game:keypressed(key)
    -- manual pause toggle
    if key == 'p' then
        self.manual_pause = not self.manual_pause
        return
    end
    -- if welcome screen is active, Enter/Space starts the game
    if self.show_welcome and (key == 'return' or key == 'kpenter' or key == 'space') then
        self.show_welcome = false
        -- ensure game state is ready
        self.manual_pause = false
        self.paused = false
        return
    end
    -- If quiz is active, handle textbox input here
    if self.quiz_active then
        if key == 'backspace' then
            -- safe for ASCII digits
            self.quiz_input = self.quiz_input:sub(1, -2)
            return
        end
        if key == 'return' or key == 'kpenter' then
            -- submit answer
            local entered = tonumber(self.quiz_input)
            if entered and self.quiz_answer and entered == self.quiz_answer then
                -- correct
                self.coins = self.coins + 100
                local msgs = self.L.quiz_correct_msgs or {"Nice! Math wizard! +100 coins","Boom! Brain power rewarded! +100 coins","Correct! You're unstoppable! +100 coins"}
                self.quiz_result_msg = msgs[math.random(#msgs)]
                self.quiz_show_answer = false
            else
                -- wrong - show correct answer
                local msgs = self.L.quiz_wrong_msgs or {"Oops! Not quite.", "Close, but no cookie.", "Nope — better luck next time."}
                self.quiz_result_msg = msgs[math.random(#msgs)]
                self.quiz_show_answer = true
                self.quiz_correct_answer = self.quiz_answer
            end
            self.quiz_result_timer = self.quiz_result_duration
            return
        end
        -- accept digits, minus and space
        if #key == 1 and key:match('%d') or key == '-' then
            self.quiz_input = self.quiz_input .. key
            return
        end
        return
    end
    if self.game_over and key == 'r' then
        -- Restart
        self.unicorn = require('unicorn'):new(self.width / 2, self.height / 2, self.ground, self.width)
        self.coins = 100
        self.game_over = false
        self.stage = 1
        self.lives = 3
        self.trolls = {}
        self.troll_pool = {}
        self:addTroll(math.random(0, self.width), -10, 200)
    end
end

return Game