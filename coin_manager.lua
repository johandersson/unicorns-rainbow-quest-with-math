-- coin_manager.lua
-- Manages field coins (spawning, updating, collecting, pooling)
CoinManager = {}

function CoinManager:new(width, height, coin_radius, coin_lifetime, spawn_interval)
    local obj = {
        width = width,
        height = height,
        coin_radius = coin_radius or 18,
        coin_lifetime = coin_lifetime or 30.0,
        spawn_interval = spawn_interval or 12.0,
        field_coins = {},
        coin_pool = {},
        coin_spawn_timer = 0,
        progress_coins = 0
    }
    
    setmetatable(obj, self)
    self.__index = self
    
    return obj
end

function CoinManager:spawnCoin()
    local cx = math.random(40, self.width - 40)
    -- Place coins in upper play area
    local upper_max = math.max(60, math.floor(self.height * 0.35))
    local cy = math.random(30, upper_max)
    
    local Coin = require('coin')
    local coin
    if #self.coin_pool > 0 then
        coin = table.remove(self.coin_pool)
        coin:reset(cx, cy, self.coin_lifetime, self.coin_radius)
    else
        coin = Coin:new(cx, cy, self.coin_lifetime, self.coin_radius)
    end
    table.insert(self.field_coins, coin)
end

function CoinManager:update(dt, unicorn)
    -- Spawn new coins periodically
    self.coin_spawn_timer = self.coin_spawn_timer + dt
    if self.coin_spawn_timer >= self.spawn_interval then
        self.coin_spawn_timer = self.coin_spawn_timer - self.spawn_interval
        self:spawnCoin()
    end
    
    -- Update and collect using swap-remove
    local coins_collected = 0
    local k = 1
    while k <= #self.field_coins do
        local fc = self.field_coins[k]
        fc:update(dt)
        local collected = false
        
        if fc.t > 0 then
            if fc:isCollectedBy(unicorn) then
                collected = true
                coins_collected = coins_collected + 1
            end
        end
        
        if collected then
            self.progress_coins = self.progress_coins + 1
            -- Recycle coin
            table.insert(self.coin_pool, fc)
            self.field_coins[k] = self.field_coins[#self.field_coins]
            table.remove(self.field_coins)
        elseif fc.t <= 0 then
            -- Expired, recycle
            table.insert(self.coin_pool, fc)
            self.field_coins[k] = self.field_coins[#self.field_coins]
            table.remove(self.field_coins)
        else
            k = k + 1
        end
    end
    
    return coins_collected
end

function CoinManager:draw()
    for _, fc in ipairs(self.field_coins) do
        if type(fc.draw) == 'function' then
            fc:draw()
        else
            -- Fallback rendering
            love.graphics.setColor(1, 0.85, 0)
            love.graphics.circle('fill', fc.x, fc.y, self.coin_radius)
            love.graphics.setColor(1, 1, 0.6)
            love.graphics.circle('fill', fc.x - 4, fc.y - 4, self.coin_radius * 0.5)
            love.graphics.setColor(0.8, 0.6, 0)
            love.graphics.circle('line', fc.x, fc.y, self.coin_radius)
        end
    end
end

function CoinManager:resetProgress()
    self.progress_coins = 0
end

function CoinManager:getProgress()
    return self.progress_coins
end

return CoinManager
