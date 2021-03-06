#include "sdl_addon.h"
#include <algorithm>
#include <iostream>
#include <sstream>

// windows has apparently deprecated fopen so let's ignore that
#ifdef _WIN32
#pragma warning (disable : 4996)
#endif

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

bool sdlSetWindow(SDL_Window* window_)
{
	SDL_SysWMinfo wmi;
	SDL_VERSION(&wmi.version);
	if (!SDL_GetWindowWMInfo(window_, &wmi))
	{
		return false;
	}

	bgfx_platform_data_t pd;
#	if BX_PLATFORM_LINUX || BX_PLATFORM_FREEBSD
	pd.ndt          = wmi.info.x11.display;
	pd.nwh          = (void*)(uintptr_t)wmi.info.x11.window;
	pd.context      = NULL;
	pd.backBuffer   = NULL;
	pd.backBufferDS = NULL;
#	elif BX_PLATFORM_OSX
	pd.ndt          = NULL;
	pd.nwh          = wmi.info.cocoa.window;
	pd.context      = NULL;
	pd.backBuffer   = NULL;
	pd.backBufferDS = NULL;
#	elif BX_PLATFORM_WINDOWS
	pd.ndt          = NULL;
	pd.nwh          = wmi.info.win.window;
	pd.context      = NULL;
	pd.backBuffer   = NULL;
	pd.backBufferDS = NULL;
#	endif // BX_PLATFORM_
	bgfx_set_platform_data(&pd);

	return true;
}

SDLAddon::SDLAddon() {
	window_ = NULL;
	owner_ = NULL;
	name_ = "sdl";
	version_ = "0.0.1";
	header_ = R"(
		/* SDL Addon Embedded Header */

		#define TRUSS_SDL_EVENT_OUTOFBOUNDS 0
		#define TRUSS_SDL_EVENT_KEYDOWN     1
		#define TRUSS_SDL_EVENT_KEYUP       2
		#define TRUSS_SDL_EVENT_MOUSEDOWN   3
		#define TRUSS_SDL_EVENT_MOUSEUP     4
		#define TRUSS_SDL_EVENT_MOUSEMOVE   5
		#define TRUSS_SDL_EVENT_MOUSEWHEEL  6
		#define TRUSS_SDL_EVENT_WINDOW      7
		#define TRUSS_SDL_EVENT_TEXTINPUT   8
		#define TRUSS_SDL_EVENT_GP_ADDED     9
		#define TRUSS_SDL_EVENT_GP_REMOVED   10
		#define TRUSS_SDL_EVENT_GP_AXIS      11
		#define TRUSS_SDL_EVENT_GP_BUTTONDOWN 12
		#define TRUSS_SDL_EVENT_GP_BUTTONUP 13
		#define TRUSS_SDL_EVENT_FILEDROP    14

		typedef struct Addon Addon;
		typedef struct bgfx_callback_interface bgfx_callback_interface_t;

		typedef struct {
		    unsigned int event_type;
		    char keycode[16];
		    double x;
		    double y;
		    double dx;
		    double dy;
		    int flags;
		} truss_sdl_event;

		typedef struct {
			int x;
			int y;
			int w;
			int h;
		} truss_sdl_bounds;

		int truss_sdl_get_display_count(Addon* addon);
		truss_sdl_bounds truss_sdl_get_display_bounds(Addon* addon, int display);
		void truss_sdl_create_window(Addon* addon, int width, int height, const char* name, int is_fullscreen, int display);
		void truss_sdl_create_window_ex(Addon* addon, int x, int y, int w, int h, const char* name, int is_borderless);
		void truss_sdl_destroy_window(Addon* addon);
		void truss_sdl_resize_window(Addon* addon, int width, int height, int fullscreen);
		truss_sdl_bounds truss_sdl_window_size(Addon* addon);
		truss_sdl_bounds truss_sdl_window_gl_size(Addon* addon);
		int  truss_sdl_num_events(Addon* addon);
		truss_sdl_event truss_sdl_get_event(Addon* addon, int index);
		void truss_sdl_start_textinput(Addon* addon);
		void truss_sdl_stop_textinput(Addon* addon);
		void truss_sdl_set_clipboard(Addon* addon, const char* data);
		const char* truss_sdl_get_clipboard(Addon* addon);
		const char* truss_sdl_get_user_path(Addon* addon, const char* orgname, const char* appname);
		const char* truss_sdl_get_filedrop_path(Addon* addon);
		bgfx_callback_interface_t* truss_sdl_get_bgfx_cb(Addon* addon);
		void truss_sdl_set_relative_mouse_mode(Addon* addon, int mod);
		void truss_sdl_show_cursor(Addon* addon, int visible);
		int truss_sdl_create_cursor(Addon* addon, int cursorSlot, const unsigned char* data, const unsigned char* mask, int w, int h, int hx, int hy);
		int truss_sdl_set_cursor(Addon* addon, int cursorSlot);
		int truss_sdl_num_controllers(Addon* addon);
		int truss_sdl_enable_controller(Addon* addon, int controllerIdx);
		void truss_sdl_disable_controller(Addon* addon, int controllerIdx);
		const char* truss_sdl_get_controller_name(Addon* addon, int controllerIdx);
	)";
	errorEvent_.event_type = TRUSS_SDL_EVENT_OUTOFBOUNDS;
	for (unsigned int i = 0; i < MAX_CONTROLLERS; ++i) {
		controllers_[i] = NULL;
	}
	for (unsigned int i = 0; i < MAX_CURSORS; ++i) {
		cursors_[i] = NULL;
	}
}

const std::string& SDLAddon::getName() {
	return name_;
}

const std::string& SDLAddon::getHeader() {
	return header_;
}

const std::string& SDLAddon::getVersion() {
	return version_;
}

void SDLAddon::init(truss::Interpreter* owner) {
	owner_ = owner;
	sdlIsInit_ = false;
}

void SDLAddon::SDLinit() {
	if (sdlIsInit_) {
		return;
	}
	truss_log(TRUSS_LOG_DEBUG, "SDL Init. Segfaults near this point are likely due to video drivers that use LLVM.");
	SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1");
	SDL_SetHint(SDL_HINT_VIDEO_HIGHDPI_DISABLED, "0");
	SDL_GL_SetAttribute(SDL_GL_FRAMEBUFFER_SRGB_CAPABLE, 1);
	if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_JOYSTICK | SDL_INIT_GAMECONTROLLER) != 0) {
		std::cout << "SDL_Init Error: " << SDL_GetError() << std::endl;
		return;
	}
	sdlIsInit_ = true;
}

void SDLAddon::shutdown() {
	if (sdlIsInit_) {
		destroyWindow();
		SDL_Quit();
	}
}

void copyKeyName(truss_sdl_event& newEvent, SDL_Event& event) {
	const char* keyname = SDL_GetKeyName(event.key.keysym.sym);
	size_t namelength = std::min<size_t>(TRUSS_SDL_MAX_KEYCODE_LENGTH, strlen(keyname));
	memcpy(newEvent.keycode, keyname, namelength);
	newEvent.keycode[namelength] = '\0'; // zero terminate
}

// hand-written strncpy to get around strncpy being unsafe on
// windows and strncpy_s not existing on linux
//
// as a bonus this will actually null terminate the string
void hackCStrCpy(char* dest, char* src, size_t destsize) {
	bool reachedSrcEnd = false;
	// reserve one byte in dest for null terminator
	for (size_t i = 0; i < destsize-1; ++i) {
		if (reachedSrcEnd) {
			dest[i] = '\0';
		} else {
			dest[i] = src[i];
			reachedSrcEnd = (src[i] == '\0');
		}
	}
	dest[destsize - 1] = '\0';
}

void SDLAddon::convertAndPushEvent_(SDL_Event& event) {
	truss_sdl_event newEvent;
	bool isValid = true;
	char* temp = NULL;
	switch(event.type) {
	case SDL_KEYDOWN:
	case SDL_KEYUP:
		newEvent.event_type = (event.type == SDL_KEYDOWN ?
								TRUSS_SDL_EVENT_KEYDOWN : TRUSS_SDL_EVENT_KEYUP);
		newEvent.flags = event.key.keysym.mod;
		newEvent.x = event.key.keysym.scancode;
		newEvent.y = event.key.keysym.sym;
		copyKeyName(newEvent, event);
		break;
	case SDL_TEXTINPUT:
		newEvent.event_type = TRUSS_SDL_EVENT_TEXTINPUT;
		hackCStrCpy(newEvent.keycode, event.text.text, TRUSS_SDL_KEYCODE_BUFF_SIZE);
		break;
	case SDL_MOUSEMOTION:
		newEvent.event_type = TRUSS_SDL_EVENT_MOUSEMOVE;
		newEvent.x = event.motion.x;
		newEvent.y = event.motion.y;
		newEvent.dx = event.motion.xrel;
		newEvent.dy = event.motion.yrel;
		newEvent.flags = event.motion.state;
		break;
	case SDL_MOUSEBUTTONDOWN:
	case SDL_MOUSEBUTTONUP:
		newEvent.event_type = (event.type == SDL_MOUSEBUTTONDOWN ?
								TRUSS_SDL_EVENT_MOUSEDOWN : TRUSS_SDL_EVENT_MOUSEUP);
		newEvent.x = event.button.x;
		newEvent.y = event.button.y;
		newEvent.flags = event.button.button;
		break;
	case SDL_MOUSEWHEEL:
		newEvent.event_type = TRUSS_SDL_EVENT_MOUSEWHEEL;
		newEvent.x = event.wheel.x;
		newEvent.y = event.wheel.y;
		newEvent.flags = event.wheel.which;
		break;
	case SDL_WINDOWEVENT:
		newEvent.event_type = TRUSS_SDL_EVENT_WINDOW;
		newEvent.flags = event.window.event;
		break;
	case SDL_CONTROLLERAXISMOTION:
		newEvent.event_type = TRUSS_SDL_EVENT_GP_AXIS;
		newEvent.flags = event.caxis.which;
		newEvent.x = event.caxis.axis;
		newEvent.y = ((double)event.caxis.value) / 32767.0;
		break;
	case SDL_CONTROLLERBUTTONDOWN:
	case SDL_CONTROLLERBUTTONUP:
		newEvent.event_type = (event.type == SDL_CONTROLLERBUTTONDOWN ?
			TRUSS_SDL_EVENT_GP_BUTTONDOWN : TRUSS_SDL_EVENT_GP_BUTTONUP);
		newEvent.flags = event.cbutton.which;
		newEvent.x = event.cbutton.button;
		break;
	case SDL_CONTROLLERDEVICEADDED:
		newEvent.event_type = TRUSS_SDL_EVENT_GP_ADDED;
		newEvent.flags = event.cdevice.which;
		break;
	case SDL_CONTROLLERDEVICEREMOVED:
		newEvent.event_type = TRUSS_SDL_EVENT_GP_REMOVED;
		newEvent.flags = event.cdevice.which;
		break;
	case SDL_DROPFILE:
		newEvent.event_type = TRUSS_SDL_EVENT_FILEDROP;
		temp = event.drop.file;
		filedrop_ = temp;
		SDL_free(temp);
		break;
	default: // a whole mess of event types we don't care about
		isValid = false;
		break;
	}
	if(isValid) {
		eventBuffer_.push_back(newEvent);
	}
}

void SDLAddon::update(double dt) {
	if (!sdlIsInit_ || window_ == NULL) {
		return;
	}

	eventBuffer_.clear();

	// empty SDL event buffer by polling
	// until none left
	while (SDL_PollEvent(&event_)) {
		convertAndPushEvent_(event_);
	}
}

void SDLAddon::createWindow(int width, int height, const char* name, int is_fullscreen, int display) {
	SDLinit();
	uint32_t flags = SDL_WINDOW_SHOWN | SDL_WINDOW_ALLOW_HIGHDPI;
	if (is_fullscreen > 0) {
		flags = flags | SDL_WINDOW_BORDERLESS;
	}
	int xpos = SDL_WINDOWPOS_CENTERED;
	int ypos = SDL_WINDOWPOS_CENTERED;
	SDL_Rect bounds;
	if (SDL_GetDisplayBounds(display, &bounds) == 0) {
		if (is_fullscreen > 0) {
			xpos = bounds.x;
			ypos = bounds.y;
			width = bounds.w;
			height = bounds.h;
		} else {
			xpos = bounds.x + (bounds.w / 2) - width / 2;
			ypos = bounds.y + (bounds.h / 2) - height / 2;
		}
	} else if (is_fullscreen > 0) {
		flags = flags | SDL_WINDOW_MAXIMIZED;
	}
	window_ = SDL_CreateWindow(name
			, xpos
			, ypos
			, width
			, height
			, flags);
	registerBGFX();
}

void SDLAddon::createWindow(int x, int y, int w, int h, const char* name, int is_borderless) {
	SDLinit();
	uint32_t flags = SDL_WINDOW_SHOWN;
	if (is_borderless > 0) {
		flags = flags | SDL_WINDOW_BORDERLESS;
	}
	window_ = SDL_CreateWindow(name, x, y, w, h, flags);
	registerBGFX();
}

truss_sdl_bounds SDLAddon::windowSize() {
	truss_sdl_bounds ret;
	ret.x = 0;
	ret.y = 0;
	ret.w = -1;
	ret.h = -1;
	if (window_ == NULL) return ret;
	SDL_GetWindowSize(window_, &ret.w, &ret.h);
	return ret;
}

truss_sdl_bounds SDLAddon::windowGLSize() {
	truss_sdl_bounds ret;
	ret.x = 0;
	ret.y = 0;
	ret.w = -1;
	ret.h = -1;
	if (window_ == NULL) return ret;
	SDL_GL_GetDrawableSize(window_, &ret.w, &ret.h);
	return ret;
}

void SDLAddon::registerBGFX() {
	sdlSetWindow(window_);
}

void SDLAddon::destroyWindow() {
	std::cout << "SDLAddon::destroyWindow not implemented yet.\n";
}

void SDLAddon::resizeWindow(int width, int height, int fullscreen) {
	if (fullscreen <= 0) {
		SDL_SetWindowBordered(window_, SDL_TRUE);
		SDL_SetWindowSize(window_, width, height);
	} else {
		SDL_SetWindowBordered(window_, SDL_FALSE);
		SDL_MaximizeWindow(window_);
	}
}

int SDLAddon::openController(int controllerIdx) {
	if (controllerIdx < 0 || controllerIdx >= MAX_CONTROLLERS 
		|| !SDL_IsGameController(controllerIdx)) {
		return -1;
	}
	SDL_GameController* controller = SDL_GameControllerOpen(controllerIdx);
	SDL_Joystick* joy = SDL_GameControllerGetJoystick(controller);
	controllers_[controllerIdx] = controller;
	return SDL_JoystickInstanceID(joy);
}

void SDLAddon::closeController(int controllerIdx) {
	if (controllerIdx < 0 || controllerIdx >= MAX_CONTROLLERS) {
		return;
	}
	if (controllers_[controllerIdx]) {
		SDL_GameControllerClose(controllers_[controllerIdx]);
		controllers_[controllerIdx] = NULL;
	}
}

const char* SDLAddon::getControllerName(int controllerIdx) {
	if (controllerIdx < 0 || controllerIdx >= MAX_CONTROLLERS) {
		return NULL;
	}
	if (controllers_[controllerIdx] == NULL) {
		return NULL;
	}
	return SDL_GameControllerName(controllers_[controllerIdx]);
}

const char* SDLAddon::getClipboardText() {
	char* temp = SDL_GetClipboardText();
	clipboard_ = temp;
	SDL_free(temp);
	return clipboard_.c_str();
}

const char* SDLAddon::getFiledropText() {
	return filedrop_.c_str();
}

bool SDLAddon::createCursor(int cursorSlot, const unsigned char* data, const unsigned char* mask, int w, int h, int hx, int hy) {
	if (cursorSlot < 0 || cursorSlot >= MAX_CURSORS) return false;
	if (cursors_[cursorSlot] != NULL) {
		SDL_FreeCursor(cursors_[cursorSlot]);
		cursors_[cursorSlot] = NULL;
	}
	cursors_[cursorSlot] = SDL_CreateCursor(data, mask, w, h, hx, hy);
	return cursors_[cursorSlot] != NULL;
}

bool SDLAddon::setCursor(int slot) {
	if (slot < 0 || slot >= MAX_CURSORS) return false;
	if (cursors_[slot] != NULL) {
		SDL_SetCursor(cursors_[slot]);
		return true;
	} else {
		return false;
	}
}

void SDLAddon::showCursor(int visible) {
	SDL_ShowCursor(visible);
}

SDLAddon::~SDLAddon() {
	shutdown();
}

int SDLAddon::numEvents() {
	return (int)(eventBuffer_.size());
}

truss_sdl_event& SDLAddon::getEvent(int index) {
	if (index >= 0 && index < eventBuffer_.size()) {
		return eventBuffer_[index];
	}
	else {
		return errorEvent_;
	}
}

int truss_sdl_get_display_count(SDLAddon* addon) {
	return SDL_GetNumVideoDisplays();
}

truss_sdl_bounds truss_sdl_get_display_bounds(SDLAddon* addon, int display) {
	SDL_Rect rect;
	truss_sdl_bounds ret = {-1, -1, -1, -1};
	int happy = SDL_GetDisplayBounds(display, &rect);
	if (happy == 0) {
		ret.x = rect.x;
		ret.y = rect.y;
		ret.w = rect.w;
		ret.h = rect.h;
	}
	return ret;
}

void truss_sdl_create_window(SDLAddon* addon, int width, int height, const char* name, int is_fullscreen, int display) {
	addon->createWindow(width, height, name, is_fullscreen, display);
}

void truss_sdl_create_window_ex(SDLAddon* addon, int x, int y, int w, int h, const char* name, int is_borderless) {
	addon->createWindow(x, y, w, h, name, is_borderless);
}


void truss_sdl_destroy_window(SDLAddon* addon) {
	addon->destroyWindow();
}

void truss_sdl_resize_window(SDLAddon* addon, int width, int height, int fullscreen) {
	addon->resizeWindow(width, height, fullscreen);
}

truss_sdl_bounds truss_sdl_window_size(SDLAddon* addon) {
	return addon->windowSize();
}

truss_sdl_bounds truss_sdl_window_gl_size(SDLAddon* addon) {
	return addon->windowGLSize();
}

int  truss_sdl_num_events(SDLAddon* addon) {
	return addon->numEvents();
}

truss_sdl_event truss_sdl_get_event(SDLAddon* addon, int index) {
	return addon->getEvent(index);
}

void truss_sdl_start_textinput(SDLAddon* addon) {
	SDL_StartTextInput();
}

void truss_sdl_stop_textinput(SDLAddon* addon) {
	SDL_StopTextInput();
}

void truss_sdl_set_clipboard(SDLAddon* addon, const char* data) {
	SDL_SetClipboardText(data);
}

const char* truss_sdl_get_clipboard(SDLAddon* addon) {
	return addon->getClipboardText();
}

const char* truss_sdl_get_user_path(SDLAddon* addon, const char* orgname, const char* appname) {
	return SDL_GetPrefPath(orgname, appname);
}

const char* truss_sdl_get_filedrop_path(SDLAddon* addon) {
	return addon->getFiledropText();
}

void truss_sdl_set_relative_mouse_mode(SDLAddon* addon, int mode) {
	if (mode > 0) {
		SDL_SetRelativeMouseMode(SDL_TRUE);
	} else {
		SDL_SetRelativeMouseMode(SDL_FALSE);
	}
}

void truss_sdl_show_cursor(SDLAddon* addon, int visible) {
	addon->showCursor(visible);
}

int truss_sdl_create_cursor(SDLAddon* addon, int cursorSlot, const unsigned char* data, const unsigned char* mask, int w, int h, int hx, int hy) {
	return addon->createCursor(cursorSlot, data, mask, w, h, hx, hy) ? 1 : 0;
}

int truss_sdl_set_cursor(SDLAddon* addon, int cursorSlot) {
	return addon->setCursor(cursorSlot) ? 1 : 0;
}

int truss_sdl_num_controllers(SDLAddon* addon) {
	return SDL_NumJoysticks();
}

int truss_sdl_enable_controller(SDLAddon* addon, int controllerIdx) {
	return addon->openController(controllerIdx);
}

void truss_sdl_disable_controller(SDLAddon* addon, int controllerIdx) {
	addon->closeController(controllerIdx);
}

const char* truss_sdl_get_controller_name(SDLAddon* addon, int controllerIdx) {
	return addon->getControllerName(controllerIdx);
}

void bgfx_cb_fatal(bgfx_callback_interface_t* _this, const char* _filePath, uint16_t _line, bgfx_fatal_t _code, const char* _str) {
	std::stringstream ss;
	ss << "Fatal BGFX Error, code [" << _code << "] @" << _filePath << ":" << _line << ": " << _str;
	truss_log(TRUSS_LOG_CRITICAL, ss.str().c_str());
}

void bgfx_cb_trace_vargs(bgfx_callback_interface_t* _this, const char* _filePath, uint16_t _line, const char* _format, va_list _argList) {
	// oh boy what is this supposed to do?
	//truss_log(TRUSS_LOG_CRITICAL, "I have no clue what the trace_vargs callback is supposed to do??");
	char temp[8192];
	char* out = temp;
	int32_t len = vsnprintf(out, sizeof(temp), _format, _argList);
	if ((int32_t)sizeof(temp) < len)
	{
		out = (char*)alloca(len + 1);
		len = vsnprintf(out, len, _format, _argList);
	}
	out[len] = '\0';
	truss_log(TRUSS_LOG_DEBUG, out);
}

void bgfx_cb_profiler_begin(bgfx_callback_interface_t* _this, const char* _name, uint32_t _abgr, const char* _filePath, uint16_t _line) {
	truss_log(TRUSS_LOG_DEBUG, "Profiler begin");
}

void bgfx_cb_profiler_begin_literal(bgfx_callback_interface_t* _this, const char* _name, uint32_t _abgr, const char* _filePath, uint16_t _line) {
	truss_log(TRUSS_LOG_DEBUG, "Profiler begin literal");
}

void bgfx_cb_profiler_end(bgfx_callback_interface_t* _this) {
	truss_log(TRUSS_LOG_DEBUG, "Profiler end");
}

uint32_t bgfx_cb_cache_read_size(bgfx_callback_interface_t* _this, uint64_t _id) {
	truss_log(TRUSS_LOG_WARNING, "bgfx_cb_cache_read_size not implemented.");
	return 0;
}

bool bgfx_cb_cache_read(bgfx_callback_interface_t* _this, uint64_t _id, void* _data, uint32_t _size) {
	truss_log(TRUSS_LOG_WARNING, "bgfx_cb_cache_read not implemented.");
	return false;
}

void bgfx_cb_cache_write(bgfx_callback_interface_t* _this, uint64_t _id, const void* _data, uint32_t _size) {
	truss_log(TRUSS_LOG_WARNING, "bgfx_cb_cache_write not implemented.");
	// nothing to do
}

void swizzle(unsigned int w, unsigned int h, unsigned int pitch, char* srcdata, char* destdata, unsigned int dataSize) {
	for (unsigned int y = 0; y < h; ++y) {
		unsigned int idx = y * pitch;
		for (unsigned int x = 0; x < w; ++x) {
			destdata[idx + 0] = srcdata[idx + 2];
			destdata[idx + 1] = srcdata[idx + 1];
			destdata[idx + 2] = srcdata[idx + 0];
			destdata[idx + 3] = srcdata[idx + 3];
			idx += 4;
		}
	}
}

void bgfx_cb_screen_shot(bgfx_callback_interface_t* _this, const char* _filePath, uint32_t _width, uint32_t _height, uint32_t _pitch, const void* _data, uint32_t _size, bool _yflip) {
	truss_log(TRUSS_LOG_WARNING, "bgfx_cb_screen_shot implemented with direct writes to file!");
	truss_log(TRUSS_LOG_INFO, _filePath);
	std::stringstream ss;
	ss << "w: " << _width << ", h: " << _height << ", p: " << _pitch << ", s: " << _size << ", yf: " << _yflip;
	truss_log(TRUSS_LOG_INFO, ss.str().c_str());
	char* temp = new char[_size];
	swizzle(_width, _height, _pitch, (char*)_data, temp, _size);
	stbi_write_png(_filePath, _width, _height, 4, temp, _pitch);
	delete[] temp;
}

void bgfx_cb_capture_begin(bgfx_callback_interface_t* _this, uint32_t _width, uint32_t _height, uint32_t _pitch, bgfx_texture_format_t _format, bool _yflip) {
	truss_log(TRUSS_LOG_WARNING, "bgfx_cb_capture_begin not implemented.");
}

void bgfx_cb_capture_end(bgfx_callback_interface_t* _this) {
	truss_log(TRUSS_LOG_WARNING, "bgfx_cb_capture_end not implemented.");
}

void bgfx_cb_capture_frame(bgfx_callback_interface_t* _this, const void* _data, uint32_t _size) {
	// todo
}

static const bgfx_callback_vtbl_t sdl_vtbl = {
	bgfx_cb_fatal,
	bgfx_cb_trace_vargs,
	bgfx_cb_profiler_begin,
	bgfx_cb_profiler_begin_literal,
	bgfx_cb_profiler_end,
	bgfx_cb_cache_read_size,
	bgfx_cb_cache_read,
	bgfx_cb_cache_write,
	bgfx_cb_screen_shot,
	bgfx_cb_capture_begin,
	bgfx_cb_capture_end,
	bgfx_cb_capture_frame
};

static bgfx_callback_interface_t sdl_cb_struct = {
	&sdl_vtbl
};

bgfx_callback_interface_t* truss_sdl_get_bgfx_cb(SDLAddon* addon) {
	return &sdl_cb_struct;
}
