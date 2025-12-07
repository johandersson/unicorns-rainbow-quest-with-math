-- game.lua
Game = {}

function Game:new()
    local obj = {
        unicorn = require('unicorn'):new(400, 200),
        rainbow = require('rainbow'):new(),
        score = 0,
        game_over = false,
        ground = 550,
        stage = 1
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Game:update(dt)
    if self.game_over then return end

    local hit_ground = self.unicorn:update(dt)
    if hit_ground then
        self.game_over = true
    end

    -- Add rainbow segments while flying up
    if love.keyboard.isDown('up') then
        self.rainbow:addSegment(self.unicorn.x, self.unicorn.y, dt)
    end

    -- Check if rainbow complete
    if self.rainbow:isComplete() then
        self.score = self.score + 1
        self.stage = self.stage + 1
        self.rainbow:reset()
        -- Perhaps increase difficulty or something, but for now just score
    end
end

function Game:draw()
    -- Draw ground
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle('fill', 0, self.ground, 800, 50)

    -- Draw rainbow in background
    self.rainbow:draw()

    -- Draw unicorn
    self.unicorn:draw()

    -- Draw UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. self.score, 10, 10)
    love.graphics.print("Stage: " .. self.stage, 10, 30)

    -- Draw game over
    if self.game_over then
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf("Game Over! Press R to restart", 0, 300, 800, 'center')
    end
end

function Game:keypressed(key)
    if self.game_over and key == 'r' then
        -- Restart
        self.unicorn = require('unicorn'):new(400, 200)
        self.rainbow = require('rainbow'):new()
        self.score = 0
        self.game_over = false
        self.stage = 1
    end
end

return Game