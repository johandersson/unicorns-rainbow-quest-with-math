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
        -- Pre-created fonts to avoid per-frame allocations
        font_large = love.graphics.newFont(28),
        font_small = love.graphics.newFont(12)
        ,
        -- Quiz / math problem fields
        quiz_active = false,
        quiz_input = "",
        quiz_problem = nil,
        quiz_answer = nil,
        quiz_result_msg = nil,
        quiz_result_timer = 0,
        quiz_result_duration = 1.5,
        problems_file = 'math_problems.txt',
        problems_count = 1000
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

function Game:update(dt)
    if self.game_over then return end

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

    -- update quiz result timer (resume when finished)
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

    -- Check if reached the sun
    if self.unicorn.y < self.sun_y + 40 and math.abs(self.unicorn.x - self.sun_x) < 40 then
        self.coins = self.coins + 20
        self.stage = self.stage + 1
        -- award extra lives if coins exceed threshold
        while self.coins >= self.extra_life_cost do
            self.coins = self.coins - self.extra_life_cost
            self.lives = self.lives + 1
            self.extra_life_msg = "+1 Life!"
            self.extra_life_msg_timer = self.extra_life_msg_duration
        end
        -- prepare quiz at end of stage: pause gameplay and show a random math problem
        self.paused = true
        self.quiz_active = true
        self.quiz_input = ""
        -- pick a random problem (memory-efficient: iterate file until chosen line)
        local idx = math.random(1, self.problems_count)
        local line
        local count = 0
        for l in io.lines(self.problems_file) do
            if l and l:match('%S') and not l:match('^%s*%-%-') then
                count = count + 1
                if count == idx then
                    line = l
                    break
                end
            end
        end
        if line then
            local expr, ans = line:match('^(.-)=%s*(%-?%d+)%s*$')
            if expr then
                -- trim
                expr = expr:match('^%s*(.-)%s*$')
                self.quiz_problem = expr
                self.quiz_answer = tonumber(ans)
            else
                -- fallback: show whole line and expect numeric answer after '='
                local a = line:match('=%s*(%-?%d+)')
                self.quiz_problem = line
                self.quiz_answer = tonumber(a)
            end
        else
            self.quiz_problem = "1 + 1"
            self.quiz_answer = 2
        end
        -- do not spawn new troll/unicorn until quiz finished
    end
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

    -- Draw UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Coins: " .. self.coins, 10, 10)
    love.graphics.print("Stage: " .. self.stage, 10, 30)
    love.graphics.print("Lives: " .. self.lives, 10, 50)

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

    -- Extra life message
    if self.extra_life_msg_timer and self.extra_life_msg_timer > 0 then
        love.graphics.setFont(self.font_large)
        love.graphics.setColor(1, 1, 0)
        love.graphics.printf(self.extra_life_msg or "", 0, 80, self.width, 'center')
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