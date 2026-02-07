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

-- ui_manager.lua
-- Handles all UI rendering and text caching using memoization
local IconRenderer = require('src.icon_renderer')

UIManager = {}

function UIManager:new(width, height, locale)
    local obj = {
        width = width,
        height = height,
        L = locale,
        iconRenderer = IconRenderer.new(),
        font_large = love.graphics.newFont(20),
        font_small = love.graphics.newFont(14),
        -- Memoization cache for formatted strings
        _cached_strings = {},
        -- Cache frequently used locale strings
        _locale_cache = {}
    }
    
    setmetatable(obj, self)
    self.__index = self
    
    -- Cache locale strings to avoid table lookups
    obj:updateLocaleCache()
    
    return obj
end

function UIManager:updateLocaleCache()
    self._locale_cache = {
        coins_label = self.L.coins_label or "Coins: %d",
        stage_label = self.L.stage_label or "Stage: %d (need: %d)",
        lives_label = self.L.lives_label or "Lives: %d",
        progress_label = self.L.progress_label or "Progress: %d/%d",
        game_over = self.L.game_over or "Game Over! Press R to restart",
        you_died = self.L.you_died or "You died! Lives left: %d",
        respawning = self.L.respawning or "Respawning...",
        quiz_title = self.L.quiz_title or "Math Challenge!",
        time_label = self.L.time_label or "Time: %ds",
        quiz_hint = self.L.quiz_hint or "Type the answer and press Enter. +100 coins for correct.",
        correct_answer_label = self.L.correct_answer_label or "The correct answer was:",
        -- Scoreboard
        enter_name_title = self.L.enter_name_title or "Welcome!",
        enter_name_prompt = self.L.enter_name_prompt or "Enter your name:",
        select_player_prompt = self.L.select_player_prompt or "Select player or enter new name:",
        enter_name_hint = self.L.enter_name_hint or "Press Enter to continue",
        score_label = self.L.score_label or "Score: %d",
        highscore_label = self.L.highscore_label or "High Score: %d",
        player_select_hint = self.L.player_select_hint or "↑↓ to select, Enter to choose",
        or_type_new_name = self.L.or_type_new_name or "Or type new name below:",
        highscore_celebration = self.L.highscore_celebration or "CONGRATULATIONS! New personal best!",
        play_again = self.L.play_again or "Press R to play again"
    }
end

function UIManager:cachedFormat(key, template, ...)
    local args = {...}
    local cache_key = key .. table.concat(args, "|")
    
    if not self._cached_strings[cache_key] then
        self._cached_strings[cache_key] = template:format(...)
    end
    
    return self._cached_strings[cache_key]
end

function UIManager:shadowed_print(text, x, y)
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.print(text, x + 1, y + 1)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, x, y)
end

function UIManager:drawGameStats(coins, stage, sun_hits_required, lives, progress_coins, coins_to_advance, session_score, highscore, player_name)
    love.graphics.setFont(self.font_small)
    
    -- Show player name if available
    if player_name then
        self:shadowed_print(self:cachedFormat("player", self._locale_cache.player_label or "Player: %s", player_name), 10, 10)
        self:shadowed_print(self:cachedFormat("coins", self._locale_cache.coins_label, coins), 10, 26)
        self:shadowed_print(self:cachedFormat("stage", self._locale_cache.stage_label, stage, sun_hits_required), 10, 42)
        self:shadowed_print(self:cachedFormat("lives", self._locale_cache.lives_label, lives), 10, 58)
        self:shadowed_print(self:cachedFormat("progress", self._locale_cache.progress_label, progress_coins, coins_to_advance), 10, 74)
        
        -- Show session score and high score
        if session_score then
            self:shadowed_print(self:cachedFormat("score", self._locale_cache.score_label, session_score), 10, 90)
        end
        if highscore then
            self:shadowed_print(self:cachedFormat("highscore", self._locale_cache.highscore_label, highscore), 10, 106)
        end
    else
        self:shadowed_print(self:cachedFormat("coins", self._locale_cache.coins_label, coins), 10, 10)
        self:shadowed_print(self:cachedFormat("stage", self._locale_cache.stage_label, stage, sun_hits_required), 10, 26)
        self:shadowed_print(self:cachedFormat("lives", self._locale_cache.lives_label, lives), 10, 42)
        self:shadowed_print(self:cachedFormat("progress", self._locale_cache.progress_label, progress_coins, coins_to_advance), 10, 58)
        
        -- Show session score and high score
        if session_score then
            self:shadowed_print(self:cachedFormat("score", self._locale_cache.score_label, session_score), 10, 74)
        end
        if highscore then
            self:shadowed_print(self:cachedFormat("highscore", self._locale_cache.highscore_label, highscore), 10, 90)
        end
    end
end

function UIManager:drawGameOver()
    love.graphics.setColor(1, 0, 0)
    love.graphics.printf(self._locale_cache.game_over, 0, self.height / 2, self.width, 'center')
end

function UIManager:drawDeathOverlay(flash_alpha, lives)
    love.graphics.setColor(0, 0, 0, 0.4 * flash_alpha)
    love.graphics.rectangle('fill', 0, 0, self.width, self.height)

    love.graphics.setColor(1, 1, 1)
    local msg = self._locale_cache.you_died:format(lives)
    love.graphics.setFont(self.font_large)
    love.graphics.printf(msg, 0, self.height / 2 - 20, self.width, 'center')

    love.graphics.setFont(self.font_small)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(self._locale_cache.respawning, 0, self.height / 2 + 20, self.width, 'center')
end

function UIManager:drawMessage(message, timer)
    if timer and timer > 0 then
        love.graphics.setFont(self.font_large)
        love.graphics.setColor(1, 1, 0)
        local msgw = 220
        love.graphics.printf(message or "", self.width - msgw - 10, 10, msgw, 'right')
    end
end

function UIManager:drawPauseOverlay()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle('fill', 0, 0, self.width, self.height)
    love.graphics.setFont(self.font_large)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(self._locale_cache.paused_msg or self.L.paused_msg, 0, self.height/2 - 20, self.width, 'center')
end

function UIManager:drawWelcomeScreen(top_scores, welcome_scroll_offset)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', 0, 0, self.width, self.height)
    
    -- Title and instructions at top
    love.graphics.setFont(self.font_large)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(self._locale_cache.enter_name_title or self.L.welcome_title, 0, 40, self.width, 'center')
    love.graphics.setFont(self.font_small)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.printf(self.L.welcome_desc, 0, 90, self.width, 'center')
    love.graphics.printf(self.L.controls, 0, 120, self.width, 'center')
    
    -- High scores board in the middle
    if top_scores and #top_scores > 0 then
        local board_y = 160
        local board_h = self.height - 260  -- Leave space for start message
        local max_visible = math.floor(board_h / 24)
        
        love.graphics.setColor(1, 0.84, 0)
        love.graphics.printf(self.L.highscore_board or "High Scores", 0, board_y, self.width, 'center')
        
        -- Scrollable scores list
        local start_idx = math.max(1, welcome_scroll_offset or 0)
        local end_idx = math.min(#top_scores, start_idx + max_visible - 1)
        
        local y = board_y + 30
        for i = start_idx, end_idx do
            local score_data = top_scores[i]
            
            -- Draw medal icon for top 3
            if i <= 3 then
                self.iconRenderer:drawMedalIcon(self.width / 2 - 120, y - 2, i, 16)
            end
            
            local text = string.format("#%d  %s - %d", i, score_data.name, score_data.highscore)
            love.graphics.printf(text, 0, y, self.width, 'center')
            y = y + 24
        end
        
        -- Show scroll indicators
        if start_idx > 1 then
            love.graphics.setColor(1, 1, 0, 0.7)
            self.iconRenderer:drawArrowIcon(self.width / 2 - 60, board_y + 23, "up", 12)
            love.graphics.printf("▲ More above", 0, board_y + 25, self.width, 'center')
        end
        if end_idx < #top_scores then
            love.graphics.setColor(1, 1, 0, 0.7)
            self.iconRenderer:drawArrowIcon(self.width / 2 - 60, y - 2, "down", 12)
            love.graphics.printf("▼ More below", 0, y, self.width, 'center')
        end
    end
    
    -- Start instruction at bottom
    love.graphics.setColor(1, 1, 0)
    love.graphics.printf(self.L.press_start, 0, self.height - 80, self.width, 'center')
end

function UIManager:drawNameInputScreen(name_input, player_names, selected_index, dialog_renderer)
    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', 0, 0, self.width, self.height)
    
    local dialog_w = math.min(500, self.width - 60)
    local has_players = #player_names > 0
    local dialog_h = has_players and 380 or 220
    local dialog_x = (self.width - dialog_w) / 2
    local dialog_y = (self.height - dialog_h) / 2
    
    -- Draw dialog box with golden border
    dialog_renderer:drawRetroDialog(dialog_x, dialog_y, dialog_w, dialog_h, {1, 0.84, 0}, {0.05, 0.05, 0.15})
    
    -- Title
    love.graphics.setFont(self.font_large)
    love.graphics.setColor(1, 0.84, 0) -- Gold
    local title = has_players and self._locale_cache.select_player_prompt or self._locale_cache.enter_name_prompt
    love.graphics.printf(title, dialog_x, dialog_y + 20, dialog_w, 'center')
    
    local y_offset = 60
    
    -- Show player list if available
    if has_players then
        love.graphics.setFont(self.font_small)
        local list_y = dialog_y + y_offset
        local max_show = 5
        
        -- Inner function for drawing list item (optimization)
        local function drawListItem(i, name, is_selected)
            local item_y = list_y + (i - 1) * 26
            if is_selected then
                -- Bright highlight for selected item
                love.graphics.setColor(1, 0.84, 0, 0.5)
                love.graphics.rectangle('fill', dialog_x + 25, item_y - 3, dialog_w - 50, 24, 4, 4)
                love.graphics.setColor(1, 0.84, 0)
                love.graphics.setLineWidth(2)
                love.graphics.rectangle('line', dialog_x + 25, item_y - 3, dialog_w - 50, 24, 4, 4)
                love.graphics.setLineWidth(1)
            end
            love.graphics.setColor(is_selected and {1, 1, 0} or {0.9, 0.9, 0.9})
            if is_selected then
                self.iconRenderer:drawArrowIcon(dialog_x + 35, item_y - 2, "right", 12)
            end
            love.graphics.printf(name, dialog_x + 55, item_y, dialog_w - 90, 'left')
        end
        
        for i = 1, math.min(max_show, #player_names) do
            drawListItem(i, player_names[i], i == selected_index)
        end
        
        y_offset = y_offset + math.min(max_show, #player_names) * 26 + 25
        
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.printf(self._locale_cache.player_select_hint, dialog_x, dialog_y + y_offset, dialog_w, 'center')
        y_offset = y_offset + 20
        
        love.graphics.setColor(1, 1, 0)
        love.graphics.printf(self._locale_cache.or_type_new_name, dialog_x, dialog_y + y_offset, dialog_w, 'center')
        y_offset = y_offset + 25
    end
    
    -- Input box
    local input_w = 300
    local input_h = 36
    local input_x = dialog_x + (dialog_w - input_w) / 2
    local input_y = dialog_y + y_offset
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle('fill', input_x, input_y, input_w, input_h)
    love.graphics.setColor(1, 0.84, 0) -- Gold border
    love.graphics.setLineWidth(2)
    love.graphics.rectangle('line', input_x, input_y, input_w, input_h)
    love.graphics.setLineWidth(1)
    
    love.graphics.setFont(self.font_large)
    love.graphics.setColor(0, 1, 0)
    love.graphics.printf(name_input .. "_", input_x + 8, input_y + 6, input_w - 16, 'center')
    
    -- Hint
    love.graphics.setFont(self.font_small)
    love.graphics.setColor(0.7, 0.7, 0.8)
    love.graphics.printf(self._locale_cache.enter_name_hint, dialog_x, input_y + 50, dialog_w, 'center')
end

function UIManager:drawHighScoreCelebration(score_data, dialog_renderer)
    -- Static gold color (no animation)
    local gold_color = {1, 0.84, 0}
    
    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle('fill', 0, 0, self.width, self.height)
    
    local dialog_w = math.min(550, self.width - 60)
    local dialog_h = 280
    local dialog_x = (self.width - dialog_w) / 2
    local dialog_y = (self.height - dialog_h) / 2
    
    -- Static golden dialog
    dialog_renderer:drawRetroDialog(dialog_x, dialog_y, dialog_w, dialog_h, gold_color, {0.1, 0.05, 0})
    
    -- Decorative stars around title
    self.iconRenderer:drawStarIcon(dialog_x + 50, dialog_y + 22, 24)
    self.iconRenderer:drawStarIcon(dialog_x + dialog_w - 74, dialog_y + 22, 24)
    
    -- Title in gold
    love.graphics.setFont(self.font_large)
    love.graphics.setColor(1, 0.84, 0)
    love.graphics.printf(score_data.title, dialog_x, dialog_y + 25, dialog_w, 'center')
    
    -- Single static congratulation message
    love.graphics.setFont(self.font_large)
    love.graphics.setColor(1, 1, 0.6)
    love.graphics.printf(self._locale_cache.highscore_celebration, dialog_x + 20, dialog_y + 70, dialog_w - 40, 'center')
    
    -- Score details
    love.graphics.setFont(self.font_small)
    love.graphics.setColor(1, 0.9, 0.5)
    love.graphics.printf(score_data.detail, dialog_x, dialog_y + 140, dialog_w, 'center')
    
    -- Rank if available
    if score_data.rank then
        love.graphics.setColor(0.9, 0.9, 1)
        love.graphics.printf(score_data.rank, dialog_x, dialog_y + 170, dialog_w, 'center')
    end
    
    -- Continue hint
    love.graphics.setFont(self.font_small)
    love.graphics.setColor(0.7, 0.7, 0.8)
    love.graphics.printf(self._locale_cache.play_again, dialog_x, dialog_y + 220, dialog_w, 'center')
end

function UIManager:resize(w, h)
    self.width = w
    self.height = h
end

return UIManager
