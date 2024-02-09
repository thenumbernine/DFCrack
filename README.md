# DFCrack

[![Donate via Stripe](https://img.shields.io/badge/Donate-Stripe-green.svg)](https://buy.stripe.com/00gbJZ0OdcNs9zi288)<br>
[![Donate via Bitcoin](https://img.shields.io/badge/Donate-Bitcoin-green.svg)](bitcoin:37fsp7qQKU8XoHZGRQvVzQVP8FrEJ73cSJ)<br>

This is a recreation of [DFHack](https://github.com/DFHack/dfhack) in pure LuaJIT.

DFHack is great for its its C++ API, its extensibility, thread safety, and its modern Lua support.
However somewhere in the middle of using it I started thinking to myself, "This could be written in pure LuaJIT".
And so now we have this.

# The C++ Code

Right now the project-specific C++ is as minimal as possible.

The C++ code does like DFHack and overrides the four SDL functions.

From there, two Lua states are created: one per each thread run by Dwarf Fortress.

One state loads the file `dfcrack/dfmain.lua` which goes on to handle events `SDL_Init`, `SDL_Quit`, and `SDL_PollEvent` functions on the UI thread.

The other state loads the file `dfcrack/dfsim.lua`, which goes on to handle the `SDL_NumJoysticks` function run on the game simulation thread.

The release build of the result weighs in at a whopping 17kb on my machine.

# C++ External Dependencies

I'm using my dated [LuaCxx](https://github.com/thenumbernine/LuaCxx) library for lazy C++ invocation of the Lua API.  I'm sure there's better ones out there.  Meh.  Release is only 66kb on my machine.

With that comes dependency on my [Common]( https://github.com/thenumbernine/Common) library for dated C++ features that hadn't been made standard when I started writing it 10+ years ago.  Meh. Release is only 34kb on my machine.

# The LuaJIT Code

Fair warning, this code contains as little safety mechanisms as possible, versus DFHack whose API is fairly well-guarded from things like null pointers.  The goal of this is to run fast, so I'm trying to pull out a decent number of stops, at my discretion.

Right now I'm targetting Dwarf Fortress 0.47.05 / DFHack 0.47.05-r8, and only on x64 Linux.
However my goal is to bake everything into the runtime script, including DF version, architecture, and OS detection, such that the only external support it needs is the DFHack XML files specifying the Dwarf Fortress API.

I've got two versions going at the moment.  One is the manually hand crafted code in `dfcrack/byhand`.  The whole purpose of this is to just get something working and to give me an idea of how to later design the auto-generation code.
This is functioning but for some simple features, like enumerating units, printing names, printing coordinates, etc.

The second version is auto-generated from the XML files of DFHack.
Right now it auto-generates LuaJIT FFI code, 

# Lua External Dependencies

- [lua-ext](https://github.com/thenumbernine/lua-ext)
- [lua-template](https://github.com/thenumbernine/lua-template)
- [struct-lua](https://github.com/thenumbernine/struct-lua)
- [vec-ffi-lua](https://github.com/thenumbernine/vec-ffi-lua) 
- [lua-ffi-bindings](https://github.com/thenumbernine/lua-ffi-bindings) maybe if I want to make any libc calls.
- ...and probably more.  You can find the ones I forgot in my github repo.

# Building

Building the C++ code uses my proprietery [lua-make](https://github.com/thenumbernine/lua-make) system.
But this is just a thin wrapper for command-line invocations with timestamp testing.
Maybe I'll get GNU Makefile working.
No way I'm touching CMake.

# TODO

- Finish the XML-generation, and switch my current testing over from the hand-crafted code to the XML-generated code.
- Have the XML-generated code make use of [struct-lua](https://github.com/thenumbernine/struct-lua) for runtime generation and filtering of C struct fields based on DF version, for implicit `__tostring` functionality, etc.
- Have the XML-generated code also spit out some C++ code to wedge into vanilla DFHack or GDB to itself spit out more Lua code of where the C++ struct `sizeof`'s and `offsetof`'s are, for me to then again wedge into DFCrack to run-upon-detection for runtime validation that the generated fields are all aligned correct. Maybe store these in a repo somewhere since all we need is one per DF version/OS/arch build.
- Port over DFHack's `prospector` plugin to LuaJIT and do a performance comparison.
