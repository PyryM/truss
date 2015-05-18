#include "nanovg_addon.h"
#include <stb/stb_image.c>
#include <iostream>

NanoVGAddon::NanoVGAddon() {
	name_ = "nanovg";
	// TODO: have bootstrap.t prepend the standard trss_message struct onto all addon headers?
	header_ = "/*NanoVGAddon Embedded Header*/\n"
		"typedef struct Addon Addon;\n"
		"typedef struct {\n"
		"unsigned int message_type;\n"
		"unsigned int data_length;\n"
		"unsigned char* data;\n"
		"unsigned int refcount;\n"
		"} trss_message;\n"
		"trss_message* trss_nanovg_load_image(Addon* addon, const char* filename, int* w, int* h, int* n)\n";
}

const std::string& NanoVGAddon::getName() {
	return name_;
}

const std::string& NanoVGAddon::getCHeader() {
	return header_;
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
	unsigned char* img;
	stbi_set_unpremultiply_on_load(1);
	stbi_convert_iphone_png_to_rgb(1);
	// always request 4 channels (rgba) from stbi
	img = stbi_load(filename, &width, &height, &numChannels, 4);
	if (img == NULL) {
		std::cout << "Failed to load " << filename 
				  << ": " << stbi_failure_reason() << std::endl;
		return NULL;
	}
	size_t datalength = width * height * numChannels;
	trss_message* ret = trss_create_message(datalength);
	memcpy(ret->data, img, datalength);
	stbi_image_free(img);

	return ret;
}

NanoVGAddon::~NanoVGAddon() {
	// nothing to do here either really
}


TRSS_C_API trss_message* trss_nanovg_load_image(NanoVGAddon* addon, const char* filename, int* w, int* h, int* n) {
	return addon->loadImage(filename, *w, *h, *n);
}