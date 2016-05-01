#ifndef NANOVG_ADDON_HEADER_GUARD
#define NANOVG_ADDON_HEADER_GUARD

#include "../../truss.h"
#include "nanovg.h"

class NanoVGAddon : public truss::Addon {
public:
	NanoVGAddon();
	const std::string& getName();
	const std::string& getCHeader();
	const std::string& getVersionString();
	void init(truss::Interpreter* owner);
	void shutdown();
	void update(double dt);

	// loads an image
	truss_message* loadImage(const char* filename, int& width, int& height, int& numChannels);

	~NanoVGAddon(); // needed so it can be deleted cleanly
private:
	std::string name_;
	std::string version_;
	std::string header_;
};

// stbi will be unhappy if we try to implement it twice, so since
// nanovg already implements it, might as well expose stbi image loading
// functionality here
TRUSS_C_API truss_message* truss_nanovg_load_image(NanoVGAddon* addon, const char* filename, int* w, int* h, int* n);

#endif //NANOVG_ADDON_HEADER_GUARD