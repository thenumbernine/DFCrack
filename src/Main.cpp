#include "DFCrack/Main.h"
#include "LuaCxx/State.h"
#include "LuaCxx/Stack.h"
#include "LuaCxx/Ref.h"

#include <dlfcn.h>
#include <iostream>
#include <thread>	//debugging / checking thread of events vs updates vs init

struct DFCrack {
	/*
	ok there's two threads at play here
	one handle init, quit, event
	another handles update
	soo ... give each thread its own lua state?
	but then how to manage that + the package.loaded + the directory structure of scripts?
	*/
	LuaCxx::State luaMain;
	LuaCxx::State luaSim;
	DFCrack() {
//std::cout << "DFCrack::DFCrack this_thread=" << std::this_thread::get_id() << std::endl;
		luaMain
		.stack()
		.getGlobal("require")
		.push("dfc")
		.call(1, 1)
		.setGlobal("dfc");
	}
	~DFCrack() {
// trust in __gc methods to clean up?		
//std::cout << "DFCrack::DFCrack this_thread=" << std::this_thread::get_id() << std::endl;
	}
	void sdlInit() {
//std::cout << "DFCrack::sdlInit this_thread=" << std::this_thread::get_id() << std::endl;
		luaMain
		.stack()
		.getGlobal("dfc")
		.get("sdlInit")
		.call(0, 0)
		.pop();
	}
	void sdlQuit() {
std::cout << "DFCrack::sdlQuit this_thread=" << std::this_thread::get_id() << std::endl;
		luaMain
		.stack()
		.getGlobal("dfc")
		.get("sdlQuit")
		.call(0, 0)
		.pop();
	}
	bool sdlEvent(SDL_Event * ev) {
//std::cout << "DFCrack::sdlEvent begin this_thread=" << std::this_thread::get_id() << std::endl;
		bool result = true;		// true default = df handles sdl events
		luaMain
		.stack()
		.getGlobal("dfc")
		.get("event");
		lua_pushlightuserdata(luaMain.getState(), ev);	// hmm is there no way to push a cdata void* onto the stack?
		luaMain
		.stack()
		.call(1, 0)
		.pop(result)
		.pop();
//std::cout << "DFCrack::sdlEvent end this_thread=" << std::this_thread::get_id() << std::endl;
		return result;
	}
	
	// run on a separate thread
	void update() {
//std::cout << "DFCrack::update begin this_thread=" << std::this_thread::get_id() << std::endl;
		luaSim
		.stack()
		.getGlobal("dfc")
		.get("update")
		.call(0, 0)
		.pop();
//std::cout << "DFCrack::update end this_thread=" << std::this_thread::get_id() << std::endl;
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

// this is run on a dif thread ... so don't call it.
// then again ...
// this is the thread we want ...
// hmm, maybe I should just have 2 states for each 2 threads
// and some comm between them?
DFCRACK_CEXPORT int SDL_NumJoysticks() {
	crack.update();
	return 0;	//or -1 on error or something
}

DFCRACK_CEXPORT int SDL_PollEvent(SDL_Event * const event) {
//std::cout << "SDL_PollEvent" << std::endl;	
	if (!event) return 0;
	int result;
	while ((result = _SDL_PollEvent(event))) {
		if (crack.sdlEvent(event)) return result;
	}
	return 0;
}
