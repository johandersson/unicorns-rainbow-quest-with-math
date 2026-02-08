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

local IconRenderer = require('src.icon_renderer')

local SettingsManager = {}
SettingsManager.__index = SettingsManager

function SettingsManager.new(game)
    local self = setmetatable({}, SettingsManager)
    self.game = game
    self.iconRenderer = IconRenderer.new()
    self.isVisible = false
    self.selectedOption = 1 -- 1 = language
    self.settingsFile = "settings.txt"
    
    -- Load saved settings
    self:load()
    
    return self
end

function SettingsManager:load()
    local info = love.filesystem.getInfo(self.settingsFile)
    if not info then
        -- Create default settings
        self:setLanguage("sv")
        self:save()
        return
    end
    
    local content = love.filesystem.read(self.settingsFile)
    for line in content:gmatch("[^\r\n]+") do
        local key, value = line:match("^([^=]+)=(.+)$")
        if key and value then
            key = key:match("^%s*(.-)%s*$") -- trim
            value = value:match("^%s*(.-)%s*$") -- trim
            
            if key == "language" then
                self:setLanguage(value)
            end
        end
    end
end

function SettingsManager:save()
    local content = string.format("language=%s\n", self.game.currentLanguage)
    love.filesystem.write(self.settingsFile, content)
end

function SettingsManager:setLanguage(lang)
    if lang ~= "sv" and lang ~= "en" then
        lang = "sv" -- Default to Swedish
    end
    
    self.game.currentLanguage = lang
    self.game.locale = require("locales." .. lang)
    
    -- Update references in other managers
    if self.game.uiManager then
        self.game.uiManager.locale = self.game.locale
    end
    self.game.L = self.game.locale
end

function SettingsManager:toggle()
    self.isVisible = not self.isVisible
end

function SettingsManager:hide()
    self.isVisible = false
end

function SettingsManager:keypressed(key)
    if not self.isVisible then return false end
    
    if key == "escape" or key == "f2" then
        self:hide()
        return true
    elseif key == "left" or key == "right" then
        -- Toggle language
        if self.game.currentLanguage == "sv" then
            self:setLanguage("en")
        else
            self:setLanguage("sv")
        end
        self:save()
        
        -- Show brief save confirmation (will fade after a moment)
        self.saveConfirmTime = 1.5
        
        return true
    end
    
    return false
end

function SettingsManager:update(dt)
    if self.saveConfirmTime then
        self.saveConfirmTime = self.saveConfirmTime - dt
        if self.saveConfirmTime <= 0 then
            self.saveConfirmTime = nil
        end
    end
end

function SettingsManager:draw()
    if not self.isVisible then return end
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local locale = self.game.locale or self.game.L
    
    -- Fallback if locale not loaded
    if not locale then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(locale and locale.settings_loading or "Loading...", 0, h/2, w, "center")
        return
    end
    
    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Dialog box
    local dialogW, dialogH = w * 0.5, h * 0.4
    local dialogX, dialogY = (w - dialogW) / 2, (h - dialogH) / 2
    
    -- Outer gold border
    love.graphics.setColor(1, 0.84, 0, 1)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", dialogX - 2, dialogY - 2, dialogW + 4, dialogH + 4)
    
    -- Inner dialog
    love.graphics.setColor(0.15, 0.1, 0.25, 0.95)
    love.graphics.rectangle("fill", dialogX, dialogY, dialogW, dialogH)
    
    -- Title with settings icon
    love.graphics.setColor(1, 0.84, 0, 1)
    local title_text = locale.settings_title
    local font = love.graphics.getFont()
    local title_width = font:getWidth(title_text)
    local icon_size = 20
    local total_width = icon_size + 10 + title_width
    local start_x = dialogX + (dialogW - total_width) / 2
    
    self.iconRenderer:drawSettingsIcon(start_x, dialogY + 18, icon_size)
    love.graphics.printf(title_text, start_x + icon_size + 10, dialogY + 20, dialogW - (start_x + icon_size + 10 - dialogX), "left")
    
    -- Language setting
    local contentY = dialogY + 80
    love.graphics.setColor(0.5, 0.9, 1, 1)
    love.graphics.printf(locale.settings_language, dialogX + 40, contentY, dialogW - 80, "left")
    
    -- Language options
    local optionY = contentY + 40
    local optionSpacing = 50
    
    -- Swedish option
    if self.game.currentLanguage == "sv" then
        love.graphics.setColor(1, 0.84, 0, 1)
        self.iconRenderer:drawArrowIcon(dialogX + dialogW / 2 - 80, optionY - 2, "left", 12)
        love.graphics.printf(locale.settings_language_sv, dialogX + 40, optionY, dialogW - 80, "center")
        self.iconRenderer:drawArrowIcon(dialogX + dialogW / 2 + 65, optionY - 2, "right", 12)
    else
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.printf(locale.settings_language_sv, dialogX + 40, optionY, dialogW - 80, "center")
    end
    
    -- English option
    optionY = optionY + optionSpacing
    if self.game.currentLanguage == "en" then
        love.graphics.setColor(1, 0.84, 0, 1)
        self.iconRenderer:drawArrowIcon(dialogX + dialogW / 2 - 80, optionY - 2, "left", 12)
        love.graphics.printf(locale.settings_language_en, dialogX + 40, optionY, dialogW - 80, "center")
        self.iconRenderer:drawArrowIcon(dialogX + dialogW / 2 + 65, optionY - 2, "right", 12)
    else
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.printf(locale.settings_language_en, dialogX + 40, optionY, dialogW - 80, "center")
    end
    
    -- Save confirmation
    if self.saveConfirmTime then
        local alpha = math.min(1, self.saveConfirmTime)
        love.graphics.setColor(0.3, 1, 0.3, alpha)
        love.graphics.printf(locale.settings_saved, dialogX, dialogY + dialogH - 80, dialogW, "center")
    end
    
    -- Instructions
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf("← → Arrow keys to change", dialogX, dialogY + dialogH - 60, dialogW, "center")
    
    -- Close instruction
    love.graphics.setColor(1, 0.84, 0, 1)
    love.graphics.printf(locale.settings_close, dialogX, dialogY + dialogH - 35, dialogW, "center")
end

return SettingsManager
