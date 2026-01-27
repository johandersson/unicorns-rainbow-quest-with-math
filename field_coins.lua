-- field_coins.lua
local FieldCoins = {}
FieldCoins.__index = FieldCoins

function FieldCoins:new(game)
    local obj = {
        game = game,
        field_coins = {},
        coin_pool = {},
        spawn_timer = 0,
        spawn_interval = game.coin_spawn_interval or 12.0,
        coin_lifetime = game.coin_lifetime or 20.0,
        coin_radius = game.coin_radius or 12
    }
    setmetatable(obj, self)
    return obj
end

function FieldCoins:spawn()
    local cx = math.random(40, self.game.width - 40)
    local upper_max = math.max(60, math.floor(self.game.height * 0.35))
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

function FieldCoins:update(dt)
    self.spawn_timer = self.spawn_timer + dt
    if self.spawn_timer >= self.spawn_interval then
        self.spawn_timer = self.spawn_timer - self.spawn_interval
        self:spawn()
    end

    local k = 1
    while k <= #self.field_coins do
        local fc = self.field_coins[k]
        fc:update(dt)
        local collected = false
        if fc.t > 0 then
            if fc:isCollectedBy(self.game.unicorn) then
                collected = true
            end
        end
        if collected then
            self.game.progress_coins = self.game.progress_coins + 1
            self.game.coins = self.game.coins + 10
            -- localized extra coins message
            local msg = (self.game.L and self.game.L.gain_coins) or "+%d coins"
            self.game.extra_life_msg = msg:format(10)
            self.game.extra_life_msg_timer = 1.2
            table.insert(self.coin_pool, fc)
            self.field_coins[k] = self.field_coins[#self.field_coins]
            table.remove(self.field_coins)
        elseif fc.t <= 0 then
            table.insert(self.coin_pool, fc)
            self.field_coins[k] = self.field_coins[#self.field_coins]
            table.remove(self.field_coins)
        else
            k = k + 1
        end
    end
end

function FieldCoins:draw()
    for _, fc in ipairs(self.field_coins) do
        fc:draw()
    end
end

return FieldCoins
