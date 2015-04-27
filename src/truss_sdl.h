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
	~SDLAddon(); // needed so it can be deleted cleanly
private:
	SDL_Window* _window;
};

extern "C" {
	void create_window(SDLAddon* addon, int width, int height, const char* name);
	void register_bgfx(SDLAddon* addon);
	void destroy_window(SDLAddon* addon);
}

#endif