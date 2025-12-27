# Unicorn Flight with LÖVE

A LÖVE Lua game where you control a unicorn flying to the sun while avoiding scary falling trolls. **WORK IN PROGRESS**.

## Gameplay

- Fly the unicorn upward using the UP arrow key.
- Reach the sun to advance stages and earn coins.
- Avoid falling trolls that can cost lives.
- Start with 3 lives and 100 coins.
- Game ends when all lives are lost by hitting trolls or the ground.

## Prerequisites

- [LÖVE framework](https://love2d.org/) installed
- Lua and LuaRocks for unit testing:
  - Download and install LuaRocks from [luarocks.org](https://luarocks.org/)
  - Run `luarocks install busted` to install the Busted testing framework

## Running the Game

Open a terminal in the project directory and run:

```
love .
```

## Running Tests

After installing Busted, run:

```
busted spec/
```

## Project Structure

- `main.lua`: Main game entry point and LÖVE callbacks
- `game.lua`: Game logic, including unicorn, trolls, and game state
- `unicorn.lua`: Unicorn class for movement and drawing
- `troll.lua`: Troll class for falling enemies
- `conf.lua`: LÖVE configuration
- `spec/`: Unit tests directory

## Controls

- UP arrow: Fly upward
- F11: Toggle fullscreen
- ESC: Exit game (with confirmation)
- R: Restart after game over

## Assets

- Unicorn and troll graphics are procedurally generated
- Rainbow background is drawn dynamically
