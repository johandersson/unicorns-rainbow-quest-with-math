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
-- scoreboard_manager.lua
-- Manages player names and high scores with file persistence
ScoreboardManager = {}

local SCOREBOARD_DIR = "scoreboard"
local SCOREBOARD_FILE = SCOREBOARD_DIR .. "/highscores.txt"

function ScoreboardManager:new()
    local obj = {
        current_player = nil,
        players = {}, -- {name = string, highscore = number}
        session_score = 0,
        is_new_highscore = false,
        previous_highscore = 0
    }
    
    setmetatable(obj, self)
    self.__index = self
    
    -- Create scoreboard directory if it doesn't exist
    obj:ensureDirectoryExists()
    
    -- Load existing scores
    obj:loadScores()
    
    return obj
end

function ScoreboardManager:ensureDirectoryExists()
    local info = love.filesystem.getInfo(SCOREBOARD_DIR)
    if not info then
        love.filesystem.createDirectory(SCOREBOARD_DIR)
    end
end

function ScoreboardManager:loadScores()
    local info = love.filesystem.getInfo(SCOREBOARD_FILE)
    if not info then
        self.players = {}
        return
    end
    
    local content = love.filesystem.read(SCOREBOARD_FILE)
    if not content then
        self.players = {}
        return
    end
    
    self.players = {}
    -- Inner function for parsing - optimizes by avoiding repeated function lookups
    local function parseLine(line)
        local name, score = line:match("^(.+):(%d+)$")
        if name and score then
            return {name = name, highscore = tonumber(score)}
        end
    end
    
    for line in content:gmatch("[^\r\n]+") do
        local player = parseLine(line)
        if player then
            table.insert(self.players, player)
        end
    end
    
    -- Sort by highscore descending (inner function for comparison)
    table.sort(self.players, function(a, b) return a.highscore > b.highscore end)
end

function ScoreboardManager:saveScores()
    -- Build content string (inner function for line formatting)
    local function formatLine(player)
        return player.name .. ":" .. player.highscore
    end
    
    local lines = {}
    for _, player in ipairs(self.players) do
        table.insert(lines, formatLine(player))
    end
    
    local content = table.concat(lines, "\n")
    love.filesystem.write(SCOREBOARD_FILE, content)
end

function ScoreboardManager:getPlayerNames()
    local names = {}
    for _, player in ipairs(self.players) do
        table.insert(names, player.name)
    end
    return names
end

function ScoreboardManager:setCurrentPlayer(name)
    self.current_player = name
    
    -- Find existing player or create new
    local found = false
    for _, player in ipairs(self.players) do
        if player.name == name then
            self.previous_highscore = player.highscore
            found = true
            break
        end
    end
    
    if not found then
        self.previous_highscore = 0
        table.insert(self.players, {name = name, highscore = 0})
    end
end

function ScoreboardManager:addScore(points)
    self.session_score = self.session_score + points
end

function ScoreboardManager:getCurrentScore()
    return self.session_score
end

function ScoreboardManager:resetSessionScore()
    self.session_score = 0
    self.is_new_highscore = false
end

function ScoreboardManager:finalizeScore()
    if not self.current_player then return end
    
    -- Find player and update if new highscore
    for _, player in ipairs(self.players) do
        if player.name == self.current_player then
            if self.session_score > player.highscore then
                player.highscore = self.session_score
                self.is_new_highscore = true
                
                -- Re-sort after update
                table.sort(self.players, function(a, b) return a.highscore > b.highscore end)
                
                self:saveScores()
            end
            break
        end
    end
end

function ScoreboardManager:isNewHighscore()
    return self.is_new_highscore
end

function ScoreboardManager:getPreviousHighscore()
    return self.previous_highscore
end

function ScoreboardManager:getTopScores(count)
    count = count or 10
    local top = {}
    for i = 1, math.min(count, #self.players) do
        table.insert(top, self.players[i])
    end
    return top
end

function ScoreboardManager:getCurrentPlayerRank()
    if not self.current_player then return nil end
    
    for i, player in ipairs(self.players) do
        if player.name == self.current_player then
            return i
        end
    end
    return nil
end

return ScoreboardManager
