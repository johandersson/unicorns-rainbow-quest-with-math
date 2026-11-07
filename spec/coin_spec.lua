local Coin = require('src.coin')

describe("Coin", function()
    it("should collect when the unicorn touches its edge", function()
        local coin = Coin:new(100, 100, 20, 18)
        local unicorn = {
            x = 32,
            y = 100,
            width = 40,
            height = 30
        }

        assert.is_true(coin:isCollectedBy(unicorn))
    end)

    it("should collect when the unicorn crosses it between frames", function()
        local coin = Coin:new(100, 100, 20, 18)
        local unicorn = {
            previous_x = 0,
            previous_y = 100,
            x = 200,
            y = 100,
            width = 40,
            height = 30
        }

        assert.is_true(coin:isCollectedBy(unicorn))
    end)

    it("should not collect when the unicorn path misses it", function()
        local coin = Coin:new(100, 100, 20, 18)
        local unicorn = {
            previous_x = 0,
            previous_y = 200,
            x = 200,
            y = 200,
            width = 40,
            height = 30
        }

        assert.is_false(coin:isCollectedBy(unicorn))
    end)
end)
