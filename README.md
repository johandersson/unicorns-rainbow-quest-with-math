# Unicorn Flight with [LÖVE](https://love2d.org/)

Unicorn Flight is a charming, educational LÖVE game that teaches basic arithmetic while delivering light, arcade-style action. Guide your unicorn skyward, collect coins, avoid trolls, and solve short math challenges to progress — perfect for unicorn lovers of ages 7–9. Features Swedish localization and retro-style dialog boxes.

## Screenshots

<p align="center">
  <img src="images/welcome-screen.png" width="400" alt="Welcome Screen">
  <img src="images/gameplay.png" width="400" alt="Gameplay">
</p>
<p align="center">
  <img src="images/quiz-dialog.png" width="400" alt="Math Quiz Dialog">
  <img src="images/quiz-result.png" width="400" alt="Quiz Result">
</p>

## Gameplay

- **Player Profiles**: Enter your name at the start or select from previous players. High scores are automatically tracked per player!
- **Help System**: Press F1 anytime to view scrollable game instructions, tips, and controls
- **Settings**: Press F2 to change language (Swedish/English) with automatic saving
- Fly the unicorn upward using the UP arrow key and navigate with LEFT/RIGHT arrows.
- Reach the sun multiple times to advance stages and earn small coin rewards (+3 coins per touch).
- Avoid falling trolls that can cost lives.
- Start with 3 lives and 100 coins.
- Game ends when all lives are lost by hitting trolls or the ground.

**Collectible Coins**: Golden coins spawn periodically in the upper play area. Collect them to earn +10 coins each and progress toward stage advancement. Coins have a generous 78-pixel collection radius and remain visible for 30 seconds.

**Math Challenges**: Each stage advance triggers a retro-style math quiz dialog (20s time limit). Answer correctly to earn +100 coins! Wrong answers display the correct solution in a retro dialog box. Problems scale with difficulty and include both standard additions and "missing value" equations (e.g., `3 + X = 10`).

**Sound Effects**: Enjoy procedurally-generated sound effects for:
- Coin collection (bright ascending tone 800→1200 Hz)
- Sun reaches (gentle ping 1000→1200 Hz)
- Level ups (triumphant fanfare 400→800 Hz)
- Deaths (descending tone 600→200 Hz)
- All sounds generated using LÖVE's SoundData API (no external files needed)

**Scoring System**:
- +3 points for each sun touch
- +10 points per collected coin
- +100 points for correct quiz answers
- Bonus points for stage completion (50 × stage number)
- Beat your high score to see a glowing gold celebration screen!

**Progressive Difficulty**: 
- Extra lives start at 250 coins and increase by +75 coins per stage
- Troll speed and spawn rates increase with each stage
- Sun hits and coin collection requirements grow progressively

## Performance Optimizations

The game uses advanced optimization techniques:
- **Memoization**: Cached sprites, formatted strings, and locale lookups
- **Object pooling**: Recycled trolls and coins to reduce garbage collection
- **Optimized collision detection**: Squared distance calculations (no sqrt)
- **Pre-calculated constants**: Rainbow colors, collision radii cached at module level
- **Inner functions**: Strategic use of inner functions for hot paths and repeated operations
- **Component-based architecture**: Separated concerns reduce coupling and improve maintainability

## High Score System

Player names and high scores are automatically saved to `scoreboard/highscores.txt` (excluded from version control). Features:
- **Player selection**: Choose from previous players or create a new profile
- **Per-player tracking**: Each player maintains their own high score
- **Automatic saving**: Scores are saved immediately upon game over
- **Celebration screen**: New high scores display a static gold retro dialog with congratulatory message in your selected language
- **Ranking display**: See your rank among all players

## Prerequisites

- [LÖVE framework](https://love2d.org/) installed
- Lua and LuaRocks for unit testing:
  - Download and install LuaRocks from [luarocks.org](https://luarocks.org/)
  - Run `luarocks install busted` to install the Busted testing framework

This project is built for LÖVE 11.x and requires no external media assets except the unicorn sprite; everything else is drawn procedurally.

## Running the Game

Open a terminal in the project directory and run:

```
love .
```

On Windows, use the included `run_game.bat` to launch the game.

## Running Tests

After installing Busted, run:

```
busted spec/
```

## Project Structure

```
main.lua                 # Game entry point and LÖVE callbacks
conf.lua                 # LÖVE configuration
src/                     # Source code directory
  ├── game.lua          # Core game coordinator
  ├── unicorn.lua       # Player character with optimized rendering
  ├── troll.lua         # Enemy character with canvas rendering
  ├── troll_manager.lua # Troll lifecycle and pooling
  ├── quiz_manager.lua  # Math problem generation and quiz logic
  ├── coin.lua          # Collectible coin entity
  ├── coin_manager.lua  # Coin spawning and pooling
  ├── rainbow.lua       # Rainbow visual effect
  ├── ui_manager.lua    # All UI rendering with text caching
  ├── background_renderer.lua  # Static background with canvas
  ├── game_state_manager.lua   # Lives, pauses, game over state
  ├── progression_system.lua   # Stages, difficulty, coin economy
  ├── dialog_renderer.lua      # Retro dialog boxes
  ├── scoreboard_manager.lua   # Player profiles and high scores
  ├── help_manager.lua         # Scrollable help dialog
  ├── settings_manager.lua     # Language settings with persistence
  └── sound_manager.lua        # Procedural sound generation
locales/                 # Localization files
  ├── sv.lua            # Swedish (default)
  └── en.lua            # English
spec/                    # Unit tests
  ├── game_spec.lua
  ├── unicorn_spec.lua
  ├── rainbow_spec.lua
  └── main_spec.lua
images/                  # Documentation screenshots
assets/                  # Game assets
  └── sounds/           # Sound files (currently procedural)
```

## Controls

- **Arrow keys**: Navigate (UP to fly, LEFT/RIGHT to move)
- **P**: Pause/unpause game
- **F1**: Show help dialog (scrollable instructions and tips)
- **F2**: Open settings (change language: Swedish/English)
- **F11**: Toggle fullscreen
- **F12**: Take screenshot (saved to screenshots/ folder)
- **ESC**: Exit game (with confirmation)
- **R**: Restart after game over
- **Numeric keys + Enter**: Answer math challenges

## Educational Features

- **10,000 varied problems**: Age-targeted addition problems (7–9 years)
- **Time-limited quizzes**: 20 seconds per problem with countdown
- **Missing-operand equations**: Advanced challenges (e.g., `A + X = C`)
- **Retro dialog feedback**: Wrong answers show correct solution
- **Progressive difficulty**: Problems scale with player advancement

## Localization

The game supports multiple languages with runtime switching:
- **Swedish** (default): `locales/sv.lua`
- **English**: `locales/en.lua`

**Features:**
- All UI text, quiz messages, and feedback are fully localized
- Language can be changed in-game via F2 settings dialog
- Settings persist between sessions in `settings.txt`
- Both languages have complete parity (all same translation keys)

## License

**Rainbow Quest - Unicorn Flight with Math**  
Copyright (C) 2026 Johan Andersson

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

## Assets

- Unicorn sprite: `unicorn-sprite.png` (cached globally for performance)
- Troll graphics: Pre-rendered to canvas at module load
- Rainbow background: Drawn dynamically with cached colors
- All UI elements: Procedurally generated retro-style dialogs
