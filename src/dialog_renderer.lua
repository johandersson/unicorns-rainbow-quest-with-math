-- dialog_renderer.lua
-- Responsible for rendering dialog boxes and quiz UI in retro style
DialogRenderer = {}

function DialogRenderer:new(width, height)
    local obj = {
        width = width,
        height = height
    }
    
    setmetatable(obj, self)
    self.__index = self
    
    return obj
end

function DialogRenderer:drawRetroDialog(x, y, w, h, border_color, bg_color)
    border_color = border_color or {1, 1, 1}
    bg_color = bg_color or {0.1, 0.1, 0.2}
    
    -- Shadow (offset down-right)
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle('fill', x + 4, y + 4, w, h)
    
    -- Background
    love.graphics.setColor(bg_color[1], bg_color[2], bg_color[3])
    love.graphics.rectangle('fill', x, y, w, h)
    
    -- Outer border (thick retro style)
    love.graphics.setColor(border_color[1], border_color[2], border_color[3])
    love.graphics.setLineWidth(3)
    love.graphics.rectangle('line', x, y, w, h)
    
    -- Inner border for double-line effect
    love.graphics.setLineWidth(1)
    love.graphics.rectangle('line', x + 6, y + 6, w - 12, h - 12)
    
    love.graphics.setLineWidth(1) -- reset
end

function DialogRenderer:drawQuizOverlay(quiz_data, locale_cache, font_large, font_small)
    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', 0, 0, self.width, self.height)
    
    -- Main dialog box
    local dialog_w = math.min(500, self.width - 60)
    local dialog_h = 220
    local dialog_x = (self.width - dialog_w) / 2
    local dialog_y = (self.height - dialog_h) / 2 - 30
    
    self:drawRetroDialog(dialog_x, dialog_y, dialog_w, dialog_h, {0.3, 0.7, 1}, {0.05, 0.05, 0.15})
    
    -- Title
    love.graphics.setFont(font_large)
    love.graphics.setColor(1, 1, 0.3)
    love.graphics.printf(locale_cache.quiz_title, dialog_x, dialog_y + 20, dialog_w, 'center')
    
    -- Problem text
    love.graphics.setFont(font_large)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(quiz_data.problem or "", dialog_x, dialog_y + 60, dialog_w, 'center')
    
    -- Timer
    if quiz_data.timer then
        love.graphics.setFont(font_small)
        love.graphics.setColor(1, 0.8, 0.4)
        love.graphics.printf(locale_cache.time_label:format(math.ceil(quiz_data.timer)), dialog_x, dialog_y + 100, dialog_w, 'center')
    end
    
    -- Input box (retro style)
    local input_w = 260
    local input_h = 36
    local input_x = dialog_x + (dialog_w - input_w) / 2
    local input_y = dialog_y + 125
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle('fill', input_x, input_y, input_w, input_h)
    love.graphics.setColor(0.3, 0.7, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle('line', input_x, input_y, input_w, input_h)
    love.graphics.setLineWidth(1)
    
    love.graphics.setFont(font_large)
    love.graphics.setColor(0, 1, 0)
    love.graphics.printf(quiz_data.input .. "_", input_x + 8, input_y + 6, input_w - 16, 'center')
    
    -- Hint
    love.graphics.setFont(font_small)
    love.graphics.setColor(0.7, 0.7, 0.8)
    love.graphics.printf(locale_cache.quiz_hint, dialog_x, dialog_y + 175, dialog_w, 'center')
end

function DialogRenderer:drawQuizResult(result_data, locale_cache, font_large, font_small)
    -- Dim background slightly
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle('fill', 0, 0, self.width, self.height)
    
    -- Result dialog box
    local result_w = math.min(450, self.width - 80)
    local result_h = result_data.show_answer and 180 or 140
    local result_x = (self.width - result_w) / 2
    local result_y = (self.height - result_h) / 2
    
    -- Color based on success/failure
    local border_color = result_data.show_answer and {1, 0.3, 0.3} or {0.3, 1, 0.3}
    local bg_color = result_data.show_answer and {0.15, 0.05, 0.05} or {0.05, 0.15, 0.05}
    
    self:drawRetroDialog(result_x, result_y, result_w, result_h, border_color, bg_color)
    
    -- Result message
    love.graphics.setFont(font_large)
    local msg_color = result_data.show_answer and {1, 0.5, 0.5} or {0.5, 1, 0.5}
    love.graphics.setColor(msg_color[1], msg_color[2], msg_color[3])
    love.graphics.printf(result_data.message or "", result_x, result_y + 30, result_w, 'center')
    
    -- Show correct answer if wrong
    if result_data.show_answer and result_data.correct_answer then
        love.graphics.setFont(font_small)
        love.graphics.setColor(1, 1, 0.6)
        love.graphics.printf(locale_cache.correct_answer_label, result_x, result_y + 80, result_w, 'center')
        
        love.graphics.setFont(font_large)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(tostring(result_data.correct_answer), result_x, result_y + 110, result_w, 'center')
    end
end

function DialogRenderer:resize(w, h)
    self.width = w
    self.height = h
end

return DialogRenderer
