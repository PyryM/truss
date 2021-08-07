#include <stdint.h>
#include <stdbool.h>

typedef struct {
	uint8_t* data;
	void* _container;
	uint32_t datasize;
	uint32_t width;
	uint32_t height;
} bgfx_util_imagedata;

 bool igBGFXUtilDecodeImage(uint8_t* data, uint32_t datasize, bgfx_util_imagedata* dest);
 void igBGFXUtilReleaseImage(bgfx_util_imagedata* imgdata);