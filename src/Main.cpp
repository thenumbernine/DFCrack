#include "LuaCxx/State.h"
#include "LuaCxx/Stack.h"
#include "LuaCxx/Ref.h"

#include <dlfcn.h>
//#include <thread>	//debugging / checking thread of events vs updates vs init

#define DFCRACK_CEXPORT extern "C" __attribute__ ((visibility("default")))

struct SDL_Event;

struct DFCrack {
	/*
	ok there's two threads at play here
	one handle init, quit, event
	another handles update
	soo ... give each thread its own lua state?
	but then how to manage that + the package.loaded + the directory structure of scripts?
	for now i'll distinguish by naming one dfmain.lua / _G.dfmain and the other dfsim
	each state will only have its respective table defined

	so...
	dfcrack/dfmain.lua
		.sdlInit()
		.sdlQuit()
		.sdlEvent()
	dfcrack/dfsim.lua
		.update()
	.. these have to be there.  the glue code doesn't test.
	*/
	LuaCxx::State luaMain;

	LuaCxx::State luaSim;
	bool hasInitSim = {};

	DFCrack() {
		luaMain
		.stack()
		.getGlobal("require")
		.push("dfmain")
		.call(1, 1)
		.setGlobal("dfmain");
	}
	~DFCrack() {
// trust in __gc methods to clean up?
	}

	void sdlInit() {
		luaMain
		.stack()
		.getGlobal("dfmain")
		.get("sdlInit")
		.call(0, 0)
		.pop();
	}

	void sdlQuit() {
		luaMain
		.stack()
		.getGlobal("dfmain")
		.get("sdlQuit")
		.call(0, 0)
		.pop();
		// TODO here or dtor run the dfsim.quit
	}

	bool sdlEvent(SDL_Event * ev) {
		bool result = true;		// true default = df handles sdl events
#if 0	//ugh segfault why
		luaMain
		.stack()
		.getGlobal("dfmain")
		.get("sdlEvent");
//		lua_pushlightuserdata(luaMain.getState(), ev);	// hmm is there no way to push a cdata void* onto the stack?
		luaMain
		.stack()
		.call(0, 0)
		.pop(result)
		.pop();
#endif
		return result;
	}

	// run on a separate thread
	void update() {
		if (!hasInitSim) {
			hasInitSim = true;
			luaSim
			.stack()
			.getGlobal("require")
			.push("dfsim")
			.call(1, 1)
			.setGlobal("dfsim");
		}
		luaSim
		.stack()
		.getGlobal("dfsim")
		.get("update")
		.call(0, 0)
		.pop();
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
