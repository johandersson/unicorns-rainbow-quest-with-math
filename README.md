# Spel LÖVE

A starter LÖVE Lua project with unit testing enabled using Busted.

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