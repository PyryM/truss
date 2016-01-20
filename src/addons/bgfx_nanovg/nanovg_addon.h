#ifndef NANOVG_ADDON_HEADER_GUARD
#define NANOVG_ADDON_HEADER_GUARD

#include "truss.h"
#include "nanovg.h"

class NanoVGAddon : public trss::Addon {
public:
	NanoVGAddon();
	const std::string& getName();
	const std::string& getCHeader();
	const std::string& getVersionString();
	void init(trss::Interpreter* owner);
	void shutdown();
	void update(double dt);

	// loads an image
	trss_message* loadImage(const char* filename, int& width, int& height, int& numChannels);

	~NanoVGAddon(); // needed so it can be deleted cleanly
private:
	std::string name_;
	std::string version_;
	std::string header_;
};

// stbi will be unhappy if we try to implement it twice, so since
// nanovg already implements it, might as well expose stbi image loading
// functionality here
TRSS_C_API trss_message* trss_nanovg_load_image(NanoVGAddon* addon, const char* filename, int* w, int* h, int* n);

#endif //NANOVG_ADDON_HEADER_GUARD