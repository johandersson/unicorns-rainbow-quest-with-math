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

-- main.lua
local Game = require 'src.game'

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
        -- Use game locale for exit dialog
        local locale = game and game.locale
        local title = (locale and locale.exit_title) or "Exit"
        local message = (locale and locale.exit_message) or "Do you want to exit?"
        local yes = (locale and locale.exit_yes) or "Yes"
        local no = (locale and locale.exit_no) or "No"
        local result = love.window.showMessageBox(title, message, {yes, no}, "info", true)
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

function love.wheelmoved(x, y)
    if game and game.wheelmoved then
        game:wheelmoved(x, y)
    end
end

function love.mousepressed(x, y, button)
    if game and game.mousepressed then
        game:mousepressed(x, y, button)
    end
end
