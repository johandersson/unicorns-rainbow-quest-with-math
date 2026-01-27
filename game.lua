-- game.lua
Game = {}

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
        -- Extra life settings
        extra_life_cost = 200,
        extra_life_msg = nil,
        extra_life_msg_timer = 0,
        extra_life_msg_duration = 1.5,
        -- Pre-created fonts to avoid per-frame allocations (smaller for status)
        font_large = love.graphics.newFont(20),
        font_small = love.graphics.newFont(10)
        ,
        -- Quiz / math problem fields
        quiz_active = false,
        quiz_input = "",
        quiz_problem = nil,
        quiz_answer = nil,
        quiz_result_msg = nil,
        quiz_result_timer = 0,
        quiz_result_duration = 1.5,
        quiz_time_limit = 20,
        problems_file = 'math_problems.txt',
        problems_count = 10000,
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
        coin_lifetime = 20.0,
        coin_radius = 18,
        coins_to_advance = 3,
        progress_coins = 0,
        -- pre-generated math problems (filled at startup)
        problems = {},
        next_problem_index = 1
    }
    obj.ground = obj.height - 50
    obj.sun_x = obj.width / 2

        -- Create background canvas
        obj.background_canvas = love.graphics.newCanvas(obj.width, obj.height)
        love.graphics.setCanvas(obj.background_canvas)

    -- Draw rainbow background
    local rainbow_colors = {
        {1, 0, 0},     -- red
        {1, 0.5, 0},   -- orange
        {1, 1, 0},     -- yellow
        {0, 1, 0},     -- green
        {0, 0, 1},     -- blue
        {0.3, 0, 0.5}, -- indigo
        {0.5, 0, 0.5}  -- violet
    }
    for i = 1, 7 do
        love.graphics.setColor(unpack(rainbow_colors[i]))
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

    -- Generate problems list (mixture of simple addition and some missing-operand equations)
    math.randomseed(os.time())
    for i = 1, obj.problems_count do
        -- Keep difficulty appropriate for 7-9 year olds: operands mostly 1..100
        local frac = i / math.max(1, obj.problems_count)
        local maxv = 20 + math.floor(frac * 80) -- spreads up to ~100
        maxv = math.max(10, math.min(maxv, 100))
        local ptype_roll = math.random()
        if ptype_roll < 0.03 then
            -- missing-operand equation (hardest): A + X = C
            local a = math.random(1, maxv)
            local x = math.random(1, math.min(20, maxv))
            local c = a + x
            table.insert(obj.problems, {q = string.format("%d + X = %d", a, c), a = x, type = 'missing'})
        else
            -- normal addition
            local a = math.random(1, maxv)
            local b = math.random(1, math.min(maxv, 100))
            table.insert(obj.problems, {q = string.format("%d + %d", a, b), a = a + b, type = 'normal'})
        end
    end

    return obj
end

function Game:addTroll(x, y, speed)
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

function Game:updateTrolls(dt)
    -- Update trolls
    self:updateTrolls(dt)
end

function Game:spawnFieldCoin()
    local cx = math.random(40, self.width - 40)
    -- place coins above the rainbow / in the upper play area so they're easier to catch
    local upper_max = math.max(60, math.floor(self.height * 0.35))
    local cy = math.random(30, upper_max)
    local coin
    if #self.coin_pool > 0 then
        coin = table.remove(self.coin_pool)
        coin.x = cx; coin.y = cy; coin.t = self.coin_lifetime
    else
        coin = {x = cx, y = cy, t = self.coin_lifetime}
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
        fc.t = fc.t - dt
        local collected = false
        if fc.t > 0 then
            local dx = self.unicorn.x - fc.x
            local dy = self.unicorn.y - fc.y
            if (dx*dx + dy*dy) < ((self.coin_radius + 24) * (self.coin_radius + 24)) then
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

function Game:handleQuiz(dt)
    -- If a quiz result is showing, show countdown for result then resume
    if self.quiz_result_timer and self.quiz_result_timer > 0 then
        self.quiz_result_timer = self.quiz_result_timer - dt
        if self.quiz_result_timer <= 0 then
            self.quiz_result_timer = 0
            self.quiz_result_msg = nil
            -- finish quiz and resume gameplay
            self.quiz_active = false
            self.paused = false
            -- respawn unicorn and add a troll for next stage
            self.unicorn = require('unicorn'):new(self.width / 2, self.height / 2, self.ground, self.width)
            self:addTroll(math.random(0, self.width), -10, 200)
        end
        return true
    end

    -- question active: tick the quiz timer
    if self.quiz_timer then
        self.quiz_timer = self.quiz_timer - dt
        if self.quiz_timer <= 0 then
            -- timeout -> wrong
            local msgs = {"Time! Try faster next time.", "Out of time!", "Too slow!"}
            self.quiz_result_msg = msgs[math.random(#msgs)]
            self.quiz_result_timer = self.quiz_result_duration
            -- leave quiz_active true so result handler will clear later
            return true
        end
    end
    return false
end

function Game:update(dt)
    if self.game_over then return end

    -- If a quiz is active, let the quiz handler manage timing and results
    if self.quiz_active then
        self:handleQuiz(dt)
        return
    end

    local hit_ground = self.unicorn:update(dt)
    if hit_ground then
        self.lives = self.lives - 1
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

    

    -- Update trolls (swap-remove loop to avoid O(N) shifts)
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

    -- Check if reached the sun (sun hits required to level up)
    if self.unicorn.y < self.sun_y + 40 and math.abs(self.unicorn.x - self.sun_x) < 40 then
        -- reward smaller coin per hit, require multiple hits for next stage
        self.coins = self.coins + 10
        self.sun_hits = self.sun_hits + 1

        -- award extra lives if coins exceed threshold
        while self.coins >= self.extra_life_cost do
            self.coins = self.coins - self.extra_life_cost
            self.lives = self.lives + 1
            self.extra_life_msg = "+1 Life!"
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

            -- spawn a few trolls to mark the new stage
            local spawn_count = math.min(1 + math.floor(self.stage / 2), 6)
            for i = 1, spawn_count do
                local sx = math.random(0, self.width)
                local speed = self.troll_base_speed + math.random(-20, 40)
                self:addTroll(sx, -10, speed)
            end

            -- prepare quiz at stage-up (not every sun visit): pause gameplay and show a math problem
            self.paused = true
            self.quiz_active = true
            self.quiz_input = ""
            self.quiz_timer = self.quiz_time_limit
            -- select a problem from the pre-generated list
            local pick = self.next_problem_index
            if pick > #self.problems then pick = math.random(1, #self.problems) end
            local prob = self.problems[pick]
            -- bias so 'missing' type appears more often at higher stages
            if prob.type == 'missing' and math.random() < math.min(0.2 + self.stage * 0.05, 0.8) then
                self.quiz_problem = prob.q
                self.quiz_answer = prob.a
            else
                -- if picked is normal or bias failed, find a normal one nearby
                local found = prob
                if found.type ~= 'normal' then
                    for j = 1, 20 do
                        local idx = ((pick + j - 1) % #self.problems) + 1
                        if self.problems[idx].type == 'normal' then
                            found = self.problems[idx]
                            break
                        end
                    end
                end
                self.quiz_problem = found.q
                self.quiz_answer = found.a
            end
            self.next_problem_index = self.next_problem_index + 1
        elseif self.sun_hits >= self.sun_hits_required then
            -- Not enough field coins yet; encourage player to collect more
            self.extra_life_msg = "Collect " .. (self.coins_to_advance - self.progress_coins) .. " more coins to level up"
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

    -- Draw unicorn
    self.unicorn:draw()

    -- Draw trolls
    for _, entry in ipairs(self.trolls) do
        if entry.active then
            entry.troll:draw()
        end
    end

    -- Draw static collectible coins
    for _, fc in ipairs(self.field_coins) do
        -- gold outer
        love.graphics.setColor(1, 0.85, 0)
        love.graphics.circle('fill', fc.x, fc.y, self.coin_radius)
        -- inner shine
        love.graphics.setColor(1, 1, 0.6)
        love.graphics.circle('fill', fc.x - 4, fc.y - 4, self.coin_radius * 0.5)
        -- rim
        love.graphics.setColor(0.8, 0.6, 0)
        love.graphics.circle('line', fc.x, fc.y, self.coin_radius)
    end

    -- Draw UI (use smaller font for status to avoid large text)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.font_small)
    love.graphics.print("Coins: " .. self.coins, 10, 10)
    love.graphics.print("Stage: " .. self.stage .. " (need: " .. self.sun_hits_required .. ")", 10, 26)
    love.graphics.print("Lives: " .. self.lives, 10, 42)
    love.graphics.print("Progress: " .. self.progress_coins .. "/" .. self.coins_to_advance, 10, 58)

    -- Draw game over
    if self.game_over then
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf("Game Over! Press R to restart", 0, self.height / 2, self.width, 'center')
    end

    -- Death flash / message when paused
    if self.paused and not self.game_over then
        -- semi-transparent overlay
        love.graphics.setColor(0, 0, 0, 0.4 * self.flash_alpha)
        love.graphics.rectangle('fill', 0, 0, self.width, self.height)

        love.graphics.setColor(1, 1, 1)
        local msg = "You died! Lives left: " .. self.lives
        love.graphics.setFont(self.font_large)
        love.graphics.printf(msg, 0, self.height / 2 - 20, self.width, 'center')

        love.graphics.setFont(self.font_small)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Respawning...", 0, self.height / 2 + 20, self.width, 'center')
    end

    -- Extra life message (top-right so it doesn't clash with center messages)
    if self.extra_life_msg_timer and self.extra_life_msg_timer > 0 then
        love.graphics.setFont(self.font_large)
        love.graphics.setColor(1, 1, 0)
        local msgw = 220
        love.graphics.printf(self.extra_life_msg or "", self.width - msgw - 10, 10, msgw, 'right')
    end

    -- Quiz overlay
    if self.quiz_active then
        -- darken background
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle('fill', 0, 0, self.width, self.height)

        love.graphics.setFont(self.font_large)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Math Challenge!", 0, self.height/2 - 120, self.width, 'center')

        love.graphics.setFont(self.font_small)
        love.graphics.printf(self.quiz_problem or "", 0, self.height/2 - 70, self.width, 'center')

        -- show remaining time
        if self.quiz_timer then
            love.graphics.setColor(1, 0.8, 0.6)
            love.graphics.printf("Time: " .. math.ceil(self.quiz_timer) .. "s", 0, self.height/2 - 50, self.width, 'center')
            love.graphics.setColor(1,1,1)
        end

        -- input box
        local box_w, box_h = 300, 40
        local bx, by = (self.width - box_w)/2, self.height/2 - 30
        love.graphics.setColor(1,1,1)
        love.graphics.rectangle('line', bx, by, box_w, box_h)
        love.graphics.setColor(1,1,1)
        love.graphics.printf(self.quiz_input, bx + 8, by + 8, box_w - 16, 'left')

        -- hint
        love.graphics.setFont(self.font_small)
        love.graphics.setColor(0.8,0.8,0.8)
        love.graphics.printf("Type the answer and press Enter. +100 coins for correct.", 0, self.height/2 + 30, self.width, 'center')
    end

    -- Quiz result message
    if self.quiz_result_timer and self.quiz_result_timer > 0 then
        love.graphics.setFont(self.font_large)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(self.quiz_result_msg or "", 0, self.height/2 - 80, self.width, 'center')
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
    local rainbow_colors = {
        {1, 0, 0},     -- red
        {1, 0.5, 0},   -- orange
        {1, 1, 0},     -- yellow
        {0, 1, 0},     -- green
        {0, 0, 1},     -- blue
        {0.3, 0, 0.5}, -- indigo
        {0.5, 0, 0.5}  -- violet
    }
    for i = 1, 7 do
        love.graphics.setColor(unpack(rainbow_colors[i]))
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
                local msgs = {"Nice! Math wizard! +100 coins","Boom! Brain power rewarded! +100 coins","Correct! You're unstoppable! +100 coins"}
                self.quiz_result_msg = msgs[math.random(#msgs)]
            else
                local msgs = {"Oops! Not quite.", "Close, but no cookie.", "Nope — better luck next time."}
                self.quiz_result_msg = msgs[math.random(#msgs)]
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