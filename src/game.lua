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

-- game.lua
-- Main game coordinator - delegates responsibilities to specialized managers
Game = {}

function Game:new()
    local obj = {
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight(),
        unicorn = nil,
        ground = 0,
        sun_x = 0,
        sun_y = 50,
        troll_spawn_timer = 0,
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
        problems_count = 10000,
        -- Name input state
        name_input = "",
        name_input_active = true,
        selected_player_index = 1,
        show_highscore_celebration = false
    }
    obj.ground = obj.height - 50
    obj.sun_x = obj.width / 2

    obj.unicorn = require('src.unicorn'):new(obj.width / 2, obj.height / 2, obj.ground, obj.width)
    setmetatable(obj, self)
    self.__index = self

    -- Load locale and settings
    obj.currentLanguage = "sv" -- Default, will be overridden by settings
    obj.locale = require('locales.sv')
    
    -- Initialize specialized managers following Single Responsibility Principle
    obj.stateManager = require('src.game_state_manager'):new()
    obj.progressionSystem = require('src.progression_system'):new()
    obj.backgroundRenderer = require('src.background_renderer'):new(obj.width, obj.height, obj.sun_x, obj.sun_y, obj.ground)
    obj.uiManager = require('src.ui_manager'):new(obj.width, obj.height, obj.locale)
    obj.dialogRenderer = require('src.dialog_renderer'):new(obj.width, obj.height)
    obj.trollManager = require('src.troll_manager'):new(obj)
    obj.quizManager = require('src.quiz_manager'):new(obj)
    obj.scoreboardManager = require('src.scoreboard_manager'):new()
    obj.settingsManager = require('src.settings_manager'):new(obj) -- Loads saved settings
    obj.helpManager = require('src.help_manager'):new(obj)
    obj.soundManager = require('src.sound_manager'):new()
    obj.coinManager = require('src.coin_manager'):new(obj.width, obj.height, 18, 30.0, 12.0, obj)
    
    -- Update uiManager locale after settings load
    obj.uiManager.locale = obj.locale
    obj.L = obj.locale -- Backward compatibility

    obj:addTroll(math.random(0, obj.width), -10, 200)

    return obj
end

function Game:addTroll(x, y, speed)
    if self.trollManager then
        self.trollManager:add(x, y, speed)
    end
end

function Game:update(dt)
    -- Update settings manager timer
    if self.settingsManager then
        self.settingsManager:update(dt)
    end
    
    if self.stateManager.game_over then 
        -- Finalize score when game ends
        if not self.show_highscore_celebration then
            self.scoreboardManager:finalizeScore()
            self.show_highscore_celebration = self.scoreboardManager:isNewHighscore()
        end
        return 
    end
    if self.stateManager.manual_pause then return end
    if self.stateManager.show_welcome or self.name_input_active then return end
    
    -- Don't update game if help or settings are visible
    if (self.helpManager and self.helpManager.isVisible) or 
       (self.settingsManager and self.settingsManager.isVisible) then
        return
    end

    -- If a quiz is active, delegate to quiz manager
    if self.quiz_active then
        if self.quizManager then self.quizManager:update(dt) end
        return
    end

    local hit_ground = self.unicorn:update(dt)
    if hit_ground then
        local is_game_over = self.stateManager:takeDamage()
        if is_game_over then
            -- Play death sound on game over
            if self.soundManager then
                self.soundManager:play('death')
            end
            return
        end
        -- Play death sound on losing a life
        if self.soundManager then
            self.soundManager:play('death')
        end
    end

    -- If paused due to death, advance death timer and respawn when ready
    if self.stateManager.paused then
        local should_respawn = self.stateManager:updateDeathTimer(dt)
        if should_respawn then
            -- Respawn unicorn
            self.unicorn = require('src.unicorn'):new(self.width / 2, self.height / 2, self.ground, self.width)
            -- Update troll targets to the new unicorn via manager
            if self.trollManager and self.trollManager.trolls then
                for _, entry in ipairs(self.trollManager.trolls) do
                    entry.troll.target = self.unicorn
                    entry.active = true
                end
            end
        end
        return
    end

    -- Update message timer
    self.stateManager:updateMessageTimer(dt)

    -- Update trolls via manager
    if self.trollManager then
        self.trollManager:update(dt)
    end

    -- Check if reached the sun
    if self.unicorn.y < self.sun_y + 40 and math.abs(self.unicorn.x - self.sun_x) < 40 then
        self.progressionSystem:addCoins(3)
        self.scoreboardManager:addScore(3) -- Add to session score
        self.progressionSystem:incrementSunHits()
        
        -- Play sun reach sound
        if self.soundManager then
            self.soundManager:play('sun')
        end

        -- Check for extra lives
        local lives_to_add = self.progressionSystem:checkExtraLives()
        if lives_to_add > 0 then
            self.stateManager:addLives(lives_to_add)
            local lm = (self.L and self.L.gain_lives) or "+%d lives"
            self.stateManager:showMessage(lm:format(lives_to_add))
        end

        local progress_coins = self.coinManager:getProgress()
        
        -- Check if can level up
        if self.progressionSystem:canLevelUp(progress_coins) then
            self.coinManager:resetProgress()
            local spawn_count = self.progressionSystem:levelUp()
            
            -- Award stage completion bonus
            local stage_bonus = self.progressionSystem.stage * 50
            self.scoreboardManager:addScore(stage_bonus)
            
            -- Play level up sound
            if self.soundManager then
                self.soundManager:play('levelup')
            end

            -- Spawn trolls for new stage
            for i = 1, spawn_count do
                local sx = math.random(0, self.width)
                local speed = self.progressionSystem:getTrollSpeed()
                self:addTroll(sx, -10, speed)
            end

            -- Start quiz
            self.stateManager.paused = true
            if self.quizManager then
                self.quizManager:start()
            else
                self.quiz_active = true
                self.quiz_input = ""
                self.quiz_timer = self.quiz_time_limit
            end
        elseif self.progressionSystem:needsMoreCoins(progress_coins) then
            local remaining = self.progressionSystem:getRemainingCoins(progress_coins)
            local msgfmt = (self.L and self.L.collect_more) or "Collect %d more coins to level up"
            self.stateManager:showMessage(msgfmt:format(remaining), 2.0)
        end
    end

    -- Periodic troll spawning
    self.troll_spawn_timer = self.troll_spawn_timer + dt
    if self.troll_spawn_timer >= self.progressionSystem.troll_spawn_interval then
        self.troll_spawn_timer = self.troll_spawn_timer - self.progressionSystem.troll_spawn_interval
        local count = self.progressionSystem:getTrollSpawnCount()
        for i = 1, count do
            local sx = math.random(0, self.width)
            local speed = self.progressionSystem:getTrollSpeed()
            self:addTroll(sx, -10, speed)
        end
    end

    -- Update field coins
    local coins_collected = self.coinManager:update(dt, self.unicorn)
    if coins_collected > 0 then
        self.progressionSystem:addCoins(coins_collected * 10)
        self.scoreboardManager:addScore(coins_collected * 10) -- Add to session score
        self.stateManager:showMessage("+10 coins", 1.2)
    end
end


function Game:draw()
    -- Draw background
    self.backgroundRenderer:draw()

    -- Draw trolls
    if self.trollManager then
        self.trollManager:draw()
    end

    -- Draw field coins
    self.coinManager:draw()

    -- Draw unicorn on top of coins
    self.unicorn:draw()

    -- Draw UI
    self.uiManager:drawGameStats(
        self.progressionSystem:getCoins(),
        self.progressionSystem.stage,
        self.progressionSystem.sun_hits_required,
        self.stateManager.lives,
        self.coinManager:getProgress(),
        self.progressionSystem.coins_to_advance,
        self.scoreboardManager:getCurrentScore(),
        self.scoreboardManager:getPreviousHighscore(),
        self.scoreboardManager:getCurrentPlayer()
    )

    -- High score celebration (shown before game over message)
    if self.show_highscore_celebration then
        local msgs = self.L.new_highscore_msgs or {"AMAZING! You beat your record!"}
        local score_data = {
            title = self.L.new_highscore_title or "🌟 NEW HIGH SCORE! 🌟",
            message = msgs[math.random(#msgs)],
            detail = (self.L.highscore_detail or "Previous: %d → New: %d"):format(
                self.scoreboardManager:getPreviousHighscore(),
                self.scoreboardManager:getCurrentScore()
            ),
            rank = nil
        }
        
        local rank = self.scoreboardManager:getCurrentPlayerRank()
        local player_count = #self.scoreboardManager.players
        if rank and player_count > 0 then
            score_data.rank = (self.L.rank_msg or "You rank #%d out of %d players!"):format(rank, player_count)
        end
        
        self.uiManager:drawHighScoreCelebration(score_data, self.dialogRenderer)
    end

    -- Draw game over
    if self.stateManager.game_over and not self.show_highscore_celebration then
        self.uiManager:drawGameOver()
    end

    -- Death flash / message when paused
    if self.stateManager.paused and not self.stateManager.game_over then
        self.uiManager:drawDeathOverlay(self.stateManager.flash_alpha, self.stateManager.lives)
    end

    -- Extra life message
    self.uiManager:drawMessage(self.stateManager.extra_life_msg, self.stateManager.extra_life_msg_timer)

    -- Quiz overlay
    if self.quiz_active then
        local quiz_data = {
            problem = self.quiz_problem,
            timer = self.quiz_timer,
            input = self.quiz_input
        }
        self.dialogRenderer:drawQuizOverlay(quiz_data, self.uiManager._locale_cache, self.uiManager.font_large, self.uiManager.font_small)
    end

    -- Quiz result message
    if self.quiz_result_timer and self.quiz_result_timer > 0 then
        local result_data = {
            message = self.quiz_result_msg,
            show_answer = self.quiz_show_answer,
            correct_answer = self.quiz_correct_answer
        }
        self.dialogRenderer:drawQuizResult(result_data, self.uiManager._locale_cache, self.uiManager.font_large, self.uiManager.font_small)
    end

    -- Manual pause overlay
    if self.stateManager.manual_pause then
        self.uiManager:drawPauseOverlay()
    end

    -- Name input screen (shown first before game starts)
    if self.name_input_active then
        local player_names = self.scoreboardManager:getPlayerNames()
        self.uiManager:drawNameInputScreen(self.name_input, player_names, self.selected_player_index, self.dialogRenderer)
    end

    -- Welcome screen overlay (shown after name input)
    if self.stateManager.show_welcome and not self.name_input_active then
        self.uiManager:drawWelcomeScreen()
    end
    
    -- Help and settings dialogs (drawn last, on top of everything)
    if self.helpManager then
        self.helpManager:draw()
    end
    if self.settingsManager then
        self.settingsManager:draw()
    end
end


function Game:resize(w, h)
    self.width = w
    self.height = h
    self.ground = h - 50
    self.sun_x = w / 2

    -- Update all managers with new dimensions
    self.backgroundRenderer:resize(w, h, self.sun_x, self.ground)
    self.uiManager:resize(w, h)
    self.dialogRenderer:resize(w, h)
end

function Game:keypressed(key)
    -- F1 for help
    if key == 'f1' then
        if self.helpManager then
            self.helpManager:toggle()
        end
        return
    end
    
    -- F2 for settings
    if key == 'f2' then
        if self.settingsManager then
            self.settingsManager:toggle()
        end
        return
    end
    
    -- Help manager handles its own keys when visible
    if self.helpManager and self.helpManager.isVisible then
        if self.helpManager:keypressed(key) then
            return
        end
    end
    
    -- Settings manager handles its own keys when visible
    if self.settingsManager and self.settingsManager.isVisible then
        if self.settingsManager:keypressed(key) then
            return
        end
    end
    
    -- Handle name input screen
    if self.name_input_active then
        if key == 'backspace' then
            self.name_input = self.name_input:sub(1, -2)
            return
        end
        
        -- Arrow keys to navigate player list
        local player_names = self.scoreboardManager:getPlayerNames()
        if #player_names > 0 then
            if key == 'up' then
                self.selected_player_index = math.max(1, self.selected_player_index - 1)
                -- Clear input when navigating list
                self.name_input = ""
                return
            elseif key == 'down' then
                self.selected_player_index = math.min(#player_names, self.selected_player_index + 1)
                -- Clear input when navigating list
                self.name_input = ""
                return
            end
        end
        
        if key == 'return' or key == 'kpenter' then
            -- Use entered name or selected player
            local final_name
            if #self.name_input > 0 then
                -- New name typed
                final_name = self.name_input
            elseif #player_names > 0 and self.selected_player_index <= #player_names then
                -- Selected from list
                final_name = player_names[self.selected_player_index]
            else
                return -- No valid name
            end
            
            self.scoreboardManager:setCurrentPlayer(final_name)
            self.name_input_active = false
            return
        end
        
        -- Accept alphanumeric and space for name
        if #key == 1 and (key:match('%w') or key == ' ') then
            if #self.name_input < 20 then -- Limit name length
                self.name_input = self.name_input .. key
            end
            return
        end
        return
    end
    
    -- Manual pause toggle
    if key == 'p' then
        self.stateManager:togglePause()
        return
    end
    
    -- If welcome screen is active, Enter/Space starts the game
    if self.stateManager.show_welcome and (key == 'return' or key == 'kpenter' or key == 'space') then
        self.stateManager:dismissWelcome()
        return
    end
    
    -- If quiz is active, handle textbox input here
    if self.quiz_active then
        if key == 'backspace' then
            self.quiz_input = self.quiz_input:sub(1, -2)
            return
        end
        if key == 'return' or key == 'kpenter' then
            -- Submit answer
            local entered = tonumber(self.quiz_input)
            if entered and self.quiz_answer and entered == self.quiz_answer then
                -- Correct
                self.progressionSystem:addCoins(100)
                self.scoreboardManager:addScore(100) -- Add to session score
                local msgs = self.L.quiz_correct_msgs or {"Nice! Math wizard! +100 coins","Boom! Brain power rewarded! +100 coins","Correct! You're unstoppable! +100 coins"}
                self.quiz_result_msg = msgs[math.random(#msgs)]
                self.quiz_show_answer = false
            else
                -- Wrong - show correct answer
                local msgs = self.L.quiz_wrong_msgs or {"Oops! Not quite.", "Close, but no cookie.", "Nope — better luck next time."}
                self.quiz_result_msg = msgs[math.random(#msgs)]
                self.quiz_show_answer = true
                self.quiz_correct_answer = self.quiz_answer
            end
            self.quiz_result_timer = self.quiz_result_duration
            return
        end
        -- Accept digits, minus and space
        if #key == 1 and key:match('%d') or key == '-' then
            self.quiz_input = self.quiz_input .. key
            return
        end
        return
    end
    
    if self.stateManager.game_over and key == 'r' then
        -- Restart
        self.unicorn = require('src.unicorn'):new(self.width / 2, self.height / 2, self.ground, self.width)
        self.stateManager:reset()
        self.progressionSystem:reset()
        self.coinManager:resetProgress()
        self.scoreboardManager:resetSessionScore()
        self.show_highscore_celebration = false
        
        -- Reset trollManager
        if self.trollManager then
            self.trollManager.trolls = {}
            self.trollManager.pool = {}
        end
        self:addTroll(math.random(0, self.width), -10, 200)
    end
end

function Game:wheelmoved(x, y)
    -- Delegate mouse wheel to help manager for scrolling
    if self.helpManager and self.helpManager.isVisible then
        self.helpManager:wheelmoved(x, y)
    end
end

return Game