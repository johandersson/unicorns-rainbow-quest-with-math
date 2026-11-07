describe("Unicorn", function()
    it("should create with correct initial position", function()
        local u = Unicorn:new(100, 200, 550, 800)
        assert.are.equal(100, u.x)
        assert.are.equal(200, u.y)
        assert.are.equal(0, u.vx)
        assert.are.equal(0, u.vy)
    end)

    it("should move right when right key is down", function()
        local u = Unicorn:new(100, 200, 550, 800)
        -- Simulate right key down
        love.keyboard.isDown = function(key) return key == 'right' end
        u:update(0.1)
        assert.is_true(u.x > 100)
    end)

    it("should move left when left key is down", function()
        local u = Unicorn:new(100, 200, 550, 800)
        love.keyboard.isDown = function(key) return key == 'left' end
        u:update(0.1)
        assert.is_true(u.x < 100)
    end)

    it("should fly up when up key is down", function()
        local u = Unicorn:new(100, 200, 550, 800)
        love.keyboard.isDown = function(key) return key == 'up' end
        u:update(0.1)
        assert.are.equal(100, u.previous_x)
        assert.are.equal(200, u.previous_y)
        assert.is_true(u.y < 200)
    end)

    it("should fall due to gravity when not flying", function()
        local u = Unicorn:new(100, 200, 550, 800)
        love.keyboard.isDown = function() return false end
        u:update(0.1)
        assert.is_true(u.y > 200)
    end)

    it("should detect ground collision", function()
        local u = Unicorn:new(100, 540, 550, 800) -- Near ground
        love.keyboard.isDown = function() return false end
        local hit = u:update(0.1)
        assert.is_true(hit) -- Should return true for game over
    end)

    it("should clamp the top edge using its height", function()
        local u = Unicorn:new(100, 20, 550, 800)
        love.keyboard.isDown = function(key) return key == 'up' end

        u:update(0.1)

        assert.are.equal(u.height * 0.5, u.y)
    end)
end)