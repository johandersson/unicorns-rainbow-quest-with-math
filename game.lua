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
        trolls = {}
    }
    obj.ground = obj.height - 50
    obj.sun_x = obj.width / 2
    obj.unicorn = require('unicorn'):new(obj.width / 2, obj.height / 2, obj.ground, obj.width)
    table.insert(obj.trolls, require('troll'):new(math.random(0, obj.width), -10, 200))
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Game:update(dt)
    if self.game_over then return end

    local hit_ground = self.unicorn:update(dt)
    if hit_ground then
        self.lives = self.lives - 1
        if self.lives <= 0 then
            self.game_over = true
        else
            self.unicorn = require('unicorn'):new(self.width / 2, self.height / 2, self.ground, self.width)
        end
    end

    -- Update trolls
    for i, troll in ipairs(self.trolls) do
        troll:update(dt)
        if math.abs(self.unicorn.x - troll.x) < 40 and math.abs(self.unicorn.y - troll.y) < 40 then
            self.lives = self.lives - 1
            table.remove(self.trolls, i)
            if self.lives <= 0 then
                self.game_over = true
            else
                self.unicorn = require('unicorn'):new(self.width / 2, self.height / 2, self.ground, self.width)
            end
            break
        end
    end

    -- Check if reached the sun
    if self.unicorn.y < self.sun_y + 40 and math.abs(self.unicorn.x - self.sun_x) < 40 then
        self.coins = self.coins + 20
        self.stage = self.stage + 1
        self.unicorn = require('unicorn'):new(self.width / 2, self.height / 2, self.ground, self.width)
        table.insert(self.trolls, require('troll'):new(math.random(0, self.width), -10, 200))
    end
end

function Game:draw()
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
        love.graphics.arc('fill', self.width / 2, self.height, (8 - i) * 50, math.pi, 2 * math.pi)
    end

    -- Draw sun
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle('fill', self.sun_x, self.sun_y, 40)

    -- Draw ground
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.rectangle('fill', 0, self.ground, self.width, 50)

    -- Draw flowers
    love.graphics.setColor(0, 0.5, 0) -- green stems
    for i = 1, 3 do
        local x = self.width * (i / 4)
        love.graphics.line(x, self.ground, x, self.ground - 20)
    end
    love.graphics.setColor(1, 0, 0) -- red petals
    for i = 1, 3 do
        local x = self.width * (i / 4)
        love.graphics.circle('fill', x, self.ground - 20, 5)
        love.graphics.circle('fill', x - 5, self.ground - 25, 5)
        love.graphics.circle('fill', x + 5, self.ground - 25, 5)
    end
    love.graphics.setColor(1, 1, 0) -- yellow centers
    for i = 1, 3 do
        local x = self.width * (i / 4)
        love.graphics.circle('fill', x, self.ground - 20, 2)
    end

    -- Draw unicorn
    self.unicorn:draw()

    -- Draw trolls
    for _, troll in ipairs(self.trolls) do
        troll:draw()
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
end

function Game:keypressed(key)
    if self.game_over and key == 'r' then
        -- Restart
        self.unicorn = require('unicorn'):new(self.width / 2, self.height / 2, self.ground, self.width)
        self.coins = 100
        self.game_over = false
        self.stage = 1
        self.lives = 3
        self.trolls = {}
        table.insert(self.trolls, require('troll'):new(math.random(0, self.width), -10, 200))
    end
end

return Game