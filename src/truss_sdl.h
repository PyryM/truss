#ifndef TRUSS_SDL_HEADER
#define TRUSS_SDL_HEADER

class SDLAddon : public trss::Addon {
public:
	SDLAddon();
	std::string getName();
	std::string getCHeader();
	void init(trss::Interpreter* owner);
	void shutdown();
	void update(double dt);

	void createWindow(int width, int height, const char* name);
	void registerBGFX();
	void destroyWindow();

	~SDLAddon(); // needed so it can be deleted cleanly
private:
	SDL_Window* _window;
	SDL_Event _event;
	trss:Interpreter* _owner;
};

extern "C" {
	void create_window(SDLAddon* addon, int width, int height, const char* name);
	void register_bgfx(SDLAddon* addon);
	void destroy_window(SDLAddon* addon);
}

#endif