-- game_state_manager.lua
-- Manages game state (lives, paused, game over, death timer, messages)
GameStateManager = {}

function GameStateManager:new()
    local obj = {
        lives = 3,
        game_over = false,
        paused = false,
        manual_pause = false,
        show_welcome = true,
        death_timer = 0,
        respawn_delay = 1.2,
        flash_alpha = 0,
        extra_life_msg = nil,
        extra_life_msg_timer = 0,
        extra_life_msg_duration = 1.5
    }
    
    setmetatable(obj, self)
    self.__index = self
    
    return obj
end

function GameStateManager:isGameActive()
    return not self.game_over and not self.manual_pause and not self.show_welcome
end

function GameStateManager:startDeathSequence()
    self.paused = true
    self.death_timer = 0
    self.flash_alpha = 1
end

function GameStateManager:updateDeathTimer(dt)
    if not self.paused then return false end
    
    self.death_timer = self.death_timer + dt
    self.flash_alpha = math.max(0, 1 - (self.death_timer / self.respawn_delay))
    
    if self.death_timer >= self.respawn_delay then
        self.paused = false
        return true -- signal respawn needed
    end
    
    return false
end

function GameStateManager:updateMessageTimer(dt)
    if self.extra_life_msg_timer and self.extra_life_msg_timer > 0 then
        self.extra_life_msg_timer = self.extra_life_msg_timer - dt
        if self.extra_life_msg_timer <= 0 then
            self.extra_life_msg = nil
            self.extra_life_msg_timer = 0
        end
    end
end

function GameStateManager:showMessage(message, duration)
    self.extra_life_msg = message
    self.extra_life_msg_timer = duration or self.extra_life_msg_duration
end

function GameStateManager:takeDamage()
    self.lives = self.lives - 1
    if self.lives <= 0 then
        self.game_over = true
        return true -- game over
    else
        self:startDeathSequence()
        return false -- continue with lives remaining
    end
end

function GameStateManager:addLives(count)
    self.lives = self.lives + count
end

function GameStateManager:togglePause()
    self.manual_pause = not self.manual_pause
end

function GameStateManager:dismissWelcome()
    self.show_welcome = false
    self.manual_pause = false
    self.paused = false
end

function GameStateManager:reset()
    self.lives = 3
    self.game_over = false
    self.paused = false
    self.death_timer = 0
    self.flash_alpha = 0
end

return GameStateManager
