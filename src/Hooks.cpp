#include <stdio.h>
#include <dlfcn.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/shm.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <vector>
#include <string>
#include <map>

#include "DFCrack/Hooks.h"
#include <iostream>

struct DFCrack {
	DFCrack() {
		std::cout << "DFCrack::DFCrack" << std::endl;
	}
	~DFCrack() {
		std::cout << "DFCrack::DFCrack" << std::endl;
	}
	void sdlInit() {
		std::cout << "DFCrack::sdlInit" << std::endl;
	}
	void sdlQuit() {
		std::cout << "DFCrack::sdlQuit" << std::endl;
	}
	void update() {
// too much
//		std::cout << "DFCrack::update" << std::endl;
	}
	bool sdlEvent(SDL_Event const * const ev) {
//		std::cout << "DFCrack::sdlEvent" << std::endl;
		return true;
	}
};
static DFCrack crack;


static int (*_SDL_Init)(uint32_t flags) = {};
static void (*_SDL_Quit)() = {};
static int (*_SDL_PollEvent)(SDL_Event * event) = {};

DFCRACK_CEXPORT int SDL_Init(uint32_t flags) {

#define OVERRIDE(x)\
	_##x = (decltype(_##x)) dlsym(RTLD_NEXT, #x);\
	if (!_##x) throw std::runtime_error("dlsym " #x " failed");
	
	OVERRIDE(SDL_Init)
	OVERRIDE(SDL_Quit)
	OVERRIDE(SDL_PollEvent)
#undef OVERRIDE

	// TODO pre-SDL_Init? to modify the flags?
	int ret = _SDL_Init(flags);
	// TODO post-SDL_Init? to guarantee we have a SDL context?
	crack.sdlInit();
	return ret;
}

DFCRACK_CEXPORT void SDL_Quit() {
	// same questions as above, do we want a before or after or both?
	crack.sdlQuit();
	if (_SDL_Quit) {
		_SDL_Quit();
	}
}

DFCRACK_CEXPORT int SDL_NumJoysticks() {
	crack.update();
	return 0;	//or -1 on error or something
}

DFCRACK_CEXPORT int SDL_PollEvent(SDL_Event * const event) {
	if (!event) return 0;
	int result;
	while ((result = _SDL_PollEvent(event))) {
		if (crack.sdlEvent(event)) return result;
	}
	return 0;
}
