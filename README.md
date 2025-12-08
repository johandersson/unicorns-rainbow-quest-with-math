# From Unicorns with LÖVE

A starter LÖVE Lua project with unit testing enabled using Busted. **WORK IN PROGRESS**.

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

- `main.lua`: Main game file
- `conf.lua`: LÖVE configuration
- `spec/`: Unit tests directory

## Assets

- Unicorn sprite by magdum, licensed under [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/), sourced from [OpenGameArt](https://opengameart.org/content/running-unicorn)
