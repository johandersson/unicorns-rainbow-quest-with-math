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
    if key == 'f12' then
        -- Create screenshots directory if it doesn't exist
        local success = love.filesystem.createDirectory('screenshots')
        if success then
            local timestamp = os.date("%Y%m%d_%H%M%S")
            local filename = string.format("screenshots/screenshot_%s.png", timestamp)
            love.graphics.captureScreenshot(filename)
            print("Screenshot saved: " .. filename)
        end
    elseif key == 'f11' then
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