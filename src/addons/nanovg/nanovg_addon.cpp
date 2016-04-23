#include "nanovg_addon.h"
#include <stb_image.h>
#include <iostream>
#include <cstring>

NanoVGAddon::NanoVGAddon() {
	name_ = "nanovg";
	version_ = "0.0.1";
	// TODO: have bootstrap.t prepend the standard trss_message struct onto all addon headers?
	header_ = "/*NanoVGAddon Embedded Header*/\n"
		"typedef struct Addon Addon;\n"
		"typedef struct {\n"
		"unsigned int message_type;\n"
		"unsigned int data_length;\n"
		"unsigned char* data;\n"
		"unsigned int refcount;\n"
		"} trss_message;\n"
		"trss_message* trss_nanovg_load_image(Addon* addon, const char* filename, int* w, int* h, int* n);\n";
}

const std::string& NanoVGAddon::getName() {
	return name_;
}

const std::string& NanoVGAddon::getCHeader() {
	return header_;
}

const std::string& NanoVGAddon::getVersionString() {
	return version_;
}

void NanoVGAddon::init(trss::Interpreter* owner) {
	// nothing special to do
}

void NanoVGAddon::shutdown() {
	// nothing to do here either
}

void NanoVGAddon::update(double dt) {
	// no updates
}

// loads an image
trss_message* NanoVGAddon::loadImage(const char* filename, int& width, int& height, int& numChannels) {
	std::cout << "Loading " << filename << std::endl;
	unsigned char* img;
	stbi_set_unpremultiply_on_load(1);
	stbi_convert_iphone_png_to_rgb(1);
	// always request 4 channels (rgba) from stbi
	// stbi will return 4 channels, but the number reported will be
	// the actual number of channels in the source image. Since we
	// don't care about that, load that into a dummy variable and
	// return 4 channels always.
	int dummy;
	numChannels = 4;
	img = stbi_load(filename, &width, &height, &dummy, 4);
	if (img == NULL) {
		std::cout << "Failed to load " << filename 
				  << ": " << stbi_failure_reason() << std::endl;
		return NULL;
	}
	std::cout << "w: " << width << ", h: " << height << ", n: " << numChannels << std::endl;
	unsigned int datalength = width * height * numChannels;
	trss_message* ret = trss_create_message(datalength);
	std::memcpy(ret->data, img, datalength);
	stbi_image_free(img);

	return ret;
}

NanoVGAddon::~NanoVGAddon() {
	// nothing to do here either really
}


TRSS_C_API trss_message* trss_nanovg_load_image(NanoVGAddon* addon, const char* filename, int* w, int* h, int* n) {
	return addon->loadImage(filename, *w, *h, *n);
}