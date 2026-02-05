return {
    welcome_title = "Rainbow Quest - Unicorn Flight with Math",
    welcome_desc = "Collect coins, reach the sun, and solve math challenges.",
    controls = "Controls: Arrow keys to move, Up to fly, P to pause.",
    press_start = "Press Enter or Space to Start",

    paused_msg = "Paused - press P to resume",

    player_label = "Player: %s",
    coins_label = "Coins: %d",
    stage_label = "Stage: %d (need: %d)",
    lives_label = "Lives: %d",
    progress_label = "Progress: %d/%d",

    game_over = "Game Over! Press R to restart",
    you_died = "You died! Lives left: %d",
    respawning = "Respawning...",

    gain_coins = "+%d coins",
    gain_lives = "+%d lives",
    collect_more = "Collect %d more coins to level up",

    quiz_title = "Math Challenge!",
    time_label = "Time: %ds",
    quiz_hint = "Type the answer and press Enter. +100 coins for correct.",
    quiz_correct_msgs = {"Nice! +100 coins","Boom! +100 coins","Correct! +100 coins"},
    quiz_wrong_msgs = {"Oops! Not quite.", "Close, but no cookie.", "Nope — better luck next time."},
    timeout_msgs = {"Time! Try faster next time.", "Out of time!", "Too slow!"},

    -- Scoreboard
    highscore_board = "High Scores",
    enter_name_title = "Welcome!",
    enter_name_prompt = "Enter your name:",
    select_player_prompt = "Select player or enter new name:",
    enter_name_hint = "Press Enter to continue",
    score_label = "Score: %d",
    highscore_label = "High Score: %d",
    
    -- High score celebration messages
    new_highscore_title = " NEW HIGH SCORE! ",
    new_highscore_msgs = {
        "AMAZING! You beat your record!",
        "CONGRATULATIONS! New personal best!",
        "INCREDIBLE! You're a star!",
        "BRILLIANT! Record score achieved!"
    },
    highscore_detail = "Previous: %d → New: %d",
    rank_msg = "You rank #%d out of %d players!",
    
    -- Help Dialog
    help_title = " Help & Guide ",
    help_content = {
        "Welcome to Rainbow Quest!",
        "",
        "GOAL:",
        "Fly your unicorn to the sun, collect gold coins",
        "and solve fun math problems to level up!",
        "",
        "CONTROLS:",
        "↑ Arrow Key - Fly upward",
        "← → Arrow Keys - Fly sideways",
        "P - Pause game",
        "F1 - Show this help",
        "F2 - Settings",
        "",
        "HOW TO PLAY:",
        "1. Reach the sun multiple times to advance",
        "2. Collect gold coins that appear (+10 points)",
        "3. Answer math questions correctly (+100 points)",
        "4. Avoid the mean trolls!",
        "",
        "SCORING:",
        "• Sun: +3 points",
        "• Gold Coin: +10 points",
        "• Correct Answer: +100 points",
        "• Stage Bonus: 50 × stage",
        "",
        "EXTRA LIVES:",
        "Buy extra lives with coins (costs more as you",
        "progress). Starts at 250 coins.",
        "",
        "TIPS:",
        "Gold coins are easier to collect early on!",
        "Math problems get harder at higher stages.",
        "Watch out for trolls - they get faster!",
        "",
        "Have fun and good luck!"
    },
    help_copyright = "© 2026 Johan Andersson | License: GPL-3.0",
    help_close = "Press ESC or F1 to close",
    
    -- Settings Dialog
    settings_title = "⚙️ Settings",
    settings_language = "Language:",
    settings_language_sv = "Svenska",
    settings_language_en = "English",
    settings_close = "Press ESC or F2 to close",
    settings_saved = "Settings saved!",
    
    -- UI Messages
    player_select_hint = "↑↓ to select, Enter to choose",
    or_type_new_name = "Or type new name below:",
    highscore_celebration = "CONGRATULATIONS! New personal best!",
    play_again = "Press R to play again"
}
