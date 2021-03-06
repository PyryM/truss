#include "nanovg_addon.h"
#include <stb_image.h>
#include <iostream>
#include <cstring>

NanoVGAddon::NanoVGAddon() {
	name_ = "nanovg";
	version_ = "0.0.1";
	// TODO: have bootstrap.t prepend the standard truss_message struct onto all addon headers?
	header_ = R"(
		/* NanoVG Addon Embedded Header */

		typedef struct Addon Addon;
		typedef struct {
			unsigned int message_type;
			unsigned int data_length;
			unsigned char* data;
			unsigned int refcount;
		} truss_message;

		truss_message* truss_nanovg_load_image(Addon* addon, const char* filename, int* w, int* h, int* n);
	)";
}

const std::string& NanoVGAddon::getName() {
	return name_;
}

const std::string& NanoVGAddon::getHeader() {
	return header_;
}

const std::string& NanoVGAddon::getVersion() {
	return version_;
}

void NanoVGAddon::init(truss::Interpreter* owner) {
	// nothing special to do
}

void NanoVGAddon::shutdown() {
	// nothing to do here either
}

void NanoVGAddon::update(double dt) {
	// no updates
}

// loads an image
truss_message* NanoVGAddon::loadImage(const char* filename, int& width, int& height, int& numChannels) {
	unsigned char* img;
	stbi_set_unpremultiply_on_load(1);
	stbi_convert_iphone_png_to_rgb(1);
	// always request 4 channels (rgba) from stbi
	// stbi will return 4 channels, but the number reported will be
	// the actual number of channels in the source image. Since we
	// don't care about that, load that into a dummy variable and
	// return 4 channels always.
	int dummy;
	truss_message* rawfile = truss_load_file(filename);
	if (rawfile == NULL) {
		return NULL;
	}
	numChannels = 4;
	img = stbi_load_from_memory(rawfile->data, rawfile->data_length, &width, &height, &dummy, 4);
	if (img == NULL) {
		truss_log(TRUSS_LOG_ERROR, "Image loading error.");
		truss_log(TRUSS_LOG_ERROR, stbi_failure_reason());
		truss_release_message(rawfile);
		return NULL;
	}
	unsigned int datalength = width * height * numChannels;
	truss_message* ret = truss_create_message(datalength);
	std::memcpy(ret->data, img, datalength);
	stbi_image_free(img);
	truss_release_message(rawfile);

	return ret;
}

NanoVGAddon::~NanoVGAddon() {
	// nothing to do here either really
}


TRUSS_C_API truss_message* truss_nanovg_load_image(NanoVGAddon* addon, const char* filename, int* w, int* h, int* n) {
	return addon->loadImage(filename, *w, *h, *n);
}