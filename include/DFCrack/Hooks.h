#pragma once

#include <string>
#include <stdint.h>

#define DFCRACK_CEXPORT extern "C" __attribute__ ((visibility("default")))

struct SDL_Event;

DFCRACK_CEXPORT int SDL_NumJoysticks(void);
DFCRACK_CEXPORT void SDL_Quit(void);
DFCRACK_CEXPORT int SDL_PollEvent(SDL_Event * const event);
DFCRACK_CEXPORT int SDL_Init(uint32_t flags);
