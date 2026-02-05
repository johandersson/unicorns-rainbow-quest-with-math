return {
    welcome_title = "Rainbow Quest - Enhörningsflygning med Matte",
    welcome_desc = "Samla mynt, nå solen och lös mattetal.",
    controls = "Kontroller: Piltangenter för rörelse, Upp för att flyga, P för paus.",
    press_start = "Tryck Enter eller Mellanslag för att starta",

    paused_msg = "Pausad - tryck P för att återuppta",

    player_label = "Spelare: %s",
    coins_label = "Mynt: %d",
    stage_label = "Nivå: %d (behöver: %d)",
    lives_label = "Liv: %d",
    progress_label = "Framsteg: %d/%d",

    game_over = "Spelet över! Tryck R för att starta om",
    you_died = "Du dog! Liv kvar: %d",
    respawning = "Återupplivar...",

    gain_coins = "+%d mynt",
    gain_lives = "+%d liv",
    collect_more = "Skaffa %d fler mynt för att gå vidare",

    quiz_title = "Matteutmaning!",
    time_label = "Tid: %ds",
    quiz_hint = "Skriv svaret och tryck Enter. +100 mynt vid rätt svar.",
    correct_answer_label = "Det rätta svaret var:",
    quiz_correct_msgs = {"Rätt! +100 mynt", "Bra! +100 mynt", "Korrekt! +100 mynt"},
    quiz_wrong_msgs = {"Oj! Inte rätt.", "Nästan, försök igen.", "Fel — prova igen."},
    timeout_msgs = {"Tiden slut! Försök snabbare.", "Förlorad tid!", "För långsamt!"},

    -- Scoreboard
    highscore_board = "Topplista",
    enter_name_title = "Välkommen!",
    enter_name_prompt = "Ange ditt namn:",
    select_player_prompt = "Välj spelare eller skriv nytt namn:",
    enter_name_hint = "Tryck Enter för att fortsätta",
    score_label = "Poäng: %d",
    highscore_label = "Rekord: %d",
    
    -- High score celebration messages
    new_highscore_title = " NYTT REKORD! ",
    new_highscore_msgs = {
        "FANTASTISKT! Du slog ditt rekord!",
        "GRATTIS! Nytt personbästa!",
        "OTROLIGT! Du är en stjärna!",
        "BRILJANT! Rekordpoäng uppnådd!"
    },
    highscore_detail = "Förra rekord: %d → Nytt rekord: %d",
    rank_msg = "Du rankas #%d av %d spelare!",
    
    -- Help Dialog
    help_title = " Hjälp & Guide ",
    help_content = {
        "Välkommen till Rainbow Quest!",
        "",
        "MÅL:",
        "Flyg din enhörning till solen, samla guldmynt och",
        "lös roliga mattetal för att bli bättre och bättre!",
        "",
        "KONTROLLER:",
        "↑ Piltangent - Flyg uppåt",
        "← → Piltangenter - Flyg åt sidorna",
        "P - Pausa spelet",
        "F1 - Visa denna hjälp",
        "F2 - Inställningar",
        "",
        "HUR MAN SPELAR:",
        "1. Nå solen flera gånger för att gå vidare",
        "2. Samla guldmynt som dyker upp (+10 poäng)",
        "3. Svara rätt på mattetal (+100 poäng)",
        "4. Undvik de elaka trollen!",
        "",
        "POÄNG:",
        "• Sol: +3 poäng",
        "• Guldmynt: +10 poäng",
        "• Rätt svar: +100 poäng",
        "• Nivåbonus: 50 × nivå",
        "",
        "EXTRA LIV:",
        "Köp extra liv för mynt (kostar mer ju längre",
        "du kommer). Börjar på 250 mynt.",
        "",
        "TIPS:",
        "Guldmynt är lättare att samla i början!",
        "Mattetalen blir svårare ju högre nivå.",
        "Håll koll på trollen - de blir snabbare!",
        "",
        "Ha så kul och lycka till!"
    },
    help_copyright = "© 2026 Johan Andersson | Licens: GPL-3.0",
    help_close = "Tryck ESC eller F1 för att stänga",
    
    -- Settings Dialog
    settings_title = "⚙️ Inställningar",
    settings_language = "Språk:",
    settings_language_sv = "Svenska",
    settings_language_en = "English",
    settings_close = "Tryck ESC eller F2 för att stänga",
    settings_saved = "Inställningar sparade!",
    
    -- UI Messages
    player_select_hint = "↑↓ för att välja, Enter för att bekräfta",
    or_type_new_name = "Eller skriv nytt namn nedan:",
    highscore_celebration = "GRATTIS! Nytt personbästa!",
    play_again = "Tryck R för att spela igen"
}
