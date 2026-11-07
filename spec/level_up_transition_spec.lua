local Game = require('src.game')

describe("Level-up transition", function()
    local function createGame(overrides)
        local quiz_started = false
        local game = {
            settingsManager = {update = function() end, isVisible = false},
            helpManager = {isVisible = false},
            stateManager = {
                game_over = false,
                manual_pause = false,
                show_welcome = false
            },
            name_input_active = false,
            level_up_alert = {timer = 0.1},
            level_up_flash = {t = 0},
            level_up_pending_quiz = true,
            quizManager = {
                start = function()
                    quiz_started = true
                end
            }
        }

        for key, value in pairs(overrides or {}) do
            game[key] = value
        end

        setmetatable(game, {__index = Game})
        return game, function() return quiz_started end
    end

    it("finishes while the game is manually paused", function()
        local game, quizStarted = createGame({
            stateManager = {
                game_over = false,
                manual_pause = true,
                show_welcome = false
            }
        })

        game:update(0.2)

        assert.is_nil(game.level_up_alert)
        assert.is_nil(game.level_up_flash)
        assert.is_false(game.level_up_pending_quiz)
        assert.is_true(quizStarted())
    end)

    it("finishes while another modal dialog is visible", function()
        local game, quizStarted = createGame({
            helpManager = {isVisible = true}
        })

        game:update(0.2)

        assert.is_nil(game.level_up_alert)
        assert.is_true(quizStarted())
    end)

    it("cancels the pending quiz when game over takes priority", function()
        local game, quizStarted = createGame({
            stateManager = {
                game_over = true,
                manual_pause = false,
                show_welcome = false
            },
            show_highscore_celebration = true
        })

        game:update(0.2)

        assert.is_nil(game.level_up_alert)
        assert.is_nil(game.level_up_flash)
        assert.is_false(game.level_up_pending_quiz)
        assert.is_false(quizStarted())
    end)
end)
