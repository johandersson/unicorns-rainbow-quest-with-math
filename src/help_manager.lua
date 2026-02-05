local HelpManager = {}
HelpManager.__index = HelpManager

function HelpManager.new(game)
    local self = setmetatable({}, HelpManager)
    self.game = game
    self.isVisible = false
    self.scrollOffset = 0
    self.maxScroll = 0
    self.lineHeight = 24
    self.contentHeight = 0
    return self
end

function HelpManager:toggle()
    self.isVisible = not self.isVisible
    if self.isVisible then
        self.scrollOffset = 0
        self:calculateContentHeight()
    end
end

function HelpManager:hide()
    self.isVisible = false
    self.scrollOffset = 0
end

function HelpManager:calculateContentHeight()
    local locale = self.game.locale
    local content = locale.help_content
    self.contentHeight = #content * self.lineHeight + 100 -- Extra padding for title and footer
    local viewportHeight = love.graphics.getHeight() * 0.7
    self.maxScroll = math.max(0, self.contentHeight - viewportHeight)
end

function HelpManager:scroll(direction)
    if not self.isVisible then return end
    
    local scrollSpeed = 30
    self.scrollOffset = self.scrollOffset + (direction * scrollSpeed)
    self.scrollOffset = math.max(0, math.min(self.scrollOffset, self.maxScroll))
end

function HelpManager:keypressed(key)
    if not self.isVisible then return false end
    
    if key == "escape" or key == "f1" then
        self:hide()
        return true
    elseif key == "up" then
        self:scroll(-1)
        return true
    elseif key == "down" then
        self:scroll(1)
        return true
    elseif key == "pageup" then
        self:scroll(-5)
        return true
    elseif key == "pagedown" then
        self:scroll(5)
        return true
    end
    
    return false
end

function HelpManager:wheelmoved(x, y)
    if not self.isVisible then return false end
    self:scroll(-y * 2)
    return true
end

function HelpManager:draw()
    if not self.isVisible then return end
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local locale = self.game.locale
    
    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Dialog box
    local dialogW, dialogH = w * 0.8, h * 0.8
    local dialogX, dialogY = (w - dialogW) / 2, (h - dialogH) / 2
    
    -- Outer gold border
    love.graphics.setColor(1, 0.84, 0, 1)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", dialogX - 2, dialogY - 2, dialogW + 4, dialogH + 4)
    
    -- Inner dialog
    love.graphics.setColor(0.15, 0.1, 0.25, 0.95)
    love.graphics.rectangle("fill", dialogX, dialogY, dialogW, dialogH)
    
    -- Title
    love.graphics.setColor(1, 0.84, 0, 1)
    love.graphics.printf(locale.help_title, dialogX, dialogY + 20, dialogW, "center")
    
    -- Scrollable content area
    local contentX = dialogX + 40
    local contentY = dialogY + 80
    local contentW = dialogW - 80
    local contentH = dialogH - 180
    
    -- Enable scissor for scrolling
    love.graphics.setScissor(contentX, contentY, contentW, contentH)
    
    -- Draw content with scroll offset
    love.graphics.setColor(1, 1, 1, 1)
    local y = contentY - self.scrollOffset
    for i, line in ipairs(locale.help_content) do
        if line == "" then
            y = y + self.lineHeight * 0.5
        elseif line:match("^[A-ZÅÄÖ]+:$") or line:match("^•") then
            -- Headers and bullets - highlight
            love.graphics.setColor(0.5, 0.9, 1, 1)
            love.graphics.printf(line, contentX, y, contentW, "left")
            love.graphics.setColor(1, 1, 1, 1)
            y = y + self.lineHeight
        else
            love.graphics.printf(line, contentX, y, contentW, "left")
            y = y + self.lineHeight
        end
    end
    
    love.graphics.setScissor()
    
    -- Scroll indicators
    if self.scrollOffset > 0 then
        love.graphics.setColor(1, 0.84, 0, 0.8)
        love.graphics.printf("▲ Scroll Up", contentX, contentY - 25, contentW, "center")
    end
    
    if self.scrollOffset < self.maxScroll then
        love.graphics.setColor(1, 0.84, 0, 0.8)
        love.graphics.printf("▼ Scroll Down", contentX, contentY + contentH + 5, contentW, "center")
    end
    
    -- Copyright footer
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf(locale.help_copyright, dialogX, dialogY + dialogH - 60, dialogW, "center")
    
    -- Close instruction
    love.graphics.setColor(1, 0.84, 0, 1)
    love.graphics.printf(locale.help_close, dialogX, dialogY + dialogH - 35, dialogW, "center")
end

return HelpManager
