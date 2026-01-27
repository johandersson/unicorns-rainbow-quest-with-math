-- main.lua
local Game = require 'game'

local game

function love.load()
    game = Game:new()
end

function love.update(dt)
    game:update(dt)
end

function love.draw()
    love.graphics.setBackgroundColor(0.529, 0.808, 0.922)
    game:draw()
end

function love.keypressed(key)
    if key == 'f11' then
        love.window.setFullscreen(true)
    elseif key == 'escape' then
        local result = love.window.showMessageBox("Exit", "Do you want to exit?", {"Yes", "No"}, "info", true)
        if result == 1 then
            love.event.quit()
        end
    else
        game:keypressed(key)
    end
end

function love.resize(w, h)
    game:resize(w, h)
end