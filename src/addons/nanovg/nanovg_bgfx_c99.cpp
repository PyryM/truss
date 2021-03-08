/*
 * Copyright 2011-2019 Branimir Karadzic. All rights reserved.
 * License: https://github.com/bkaradzic/bgfx#license-bsd-2-clause
 */

//
// Copyright (c) 2009-2013 Mikko Mononen memon@inside.org
//
// This software is provided 'as-is', without any express or implied
// warranty.  In no event will the authors be held liable for any damages
// arising from the use of this software.
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would be
//    appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//    misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.
//
#define NVG_ANTIALIAS 1

// Needed to make gcc happy?
#define __STDC_LIMIT_MACROS
#define __STDC_CONSTANT_MACROS

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "nanovg.h"

#include <bgfx/c99/bgfx.h>
// TODO: move this define somewhere more useful
#define BGFX_INVALID_HANDLE_IDX UINT16_MAX

#include <bx/bx.h>
#include <bx/allocator.h>
#include <bx/uint32_t.h>

// Shove some BX implementations into here
#ifndef BX_CONFIG_ALLOCATOR_NATURAL_ALIGNMENT
#	define BX_CONFIG_ALLOCATOR_NATURAL_ALIGNMENT 8
#endif // BX_CONFIG_ALLOCATOR_NATURAL_ALIGNMENT

namespace bx
{
	void memCopyRef(void* _dst, const void* _src, size_t _numBytes)
	{
		uint8_t* dst = (uint8_t*)_dst;
		const uint8_t* end = dst + _numBytes;
		const uint8_t* src = (const uint8_t*)_src;
		while (dst != end)
		{
			*dst++ = *src++;
		}
	}

	void memCopy(void* _dst, const void* _src, size_t _numBytes)
	{
#if BX_CRT_NONE
		memCopyRef(_dst, _src, _numBytes);
#else
		::memcpy(_dst, _src, _numBytes);
#endif // BX_CRT_NONE
	}

	void memCopy(void* _dst, const void* _src, uint32_t _size, uint32_t _num, uint32_t _srcPitch, uint32_t _dstPitch)
	{
		const uint8_t* src = (const uint8_t*)_src;
		uint8_t* dst = (uint8_t*)_dst;

		for (uint32_t ii = 0; ii < _num; ++ii)
		{
			memCopy(dst, src, _size);
			src += _srcPitch;
			dst += _dstPitch;
		}
	}

	///
	void gather(void* _dst, const void* _src, uint32_t _size, uint32_t _num, uint32_t _srcPitch)
	{
		memCopy(_dst, _src, _size, _num, _srcPitch, _size);
	}

	///
	void scatter(void* _dst, const void* _src, uint32_t _size, uint32_t _num, uint32_t _dstPitch)
	{
		memCopy(_dst, _src, _size, _num, _size, _dstPitch);
	}

	void memMoveRef(void* _dst, const void* _src, size_t _numBytes)
	{
		uint8_t* dst = (uint8_t*)_dst;
		const uint8_t* src = (const uint8_t*)_src;

		if (_numBytes == 0
			|| dst == src)
		{
			return;
		}

		//	if (src+_numBytes <= dst || end <= src)
		if (dst < src)
		{
			memCopy(_dst, _src, _numBytes);
			return;
		}

		for (intptr_t ii = _numBytes - 1; ii >= 0; --ii)
		{
			dst[ii] = src[ii];
		}
	}

	void memMove(void* _dst, const void* _src, size_t _numBytes)
	{
#if BX_CRT_NONE
		memMoveRef(_dst, _src, _numBytes);
#else
		::memmove(_dst, _src, _numBytes);
#endif // BX_CRT_NONE
	}

	void memSetRef(void* _dst, uint8_t _ch, size_t _numBytes)
	{
		uint8_t* dst = (uint8_t*)_dst;
		const uint8_t* end = dst + _numBytes;
		while (dst != end)
		{
			*dst++ = char(_ch);
		}
	}

	void memSet(void* _dst, uint8_t _ch, size_t _numBytes)
	{
#if BX_CRT_NONE
		memSetRef(_dst, _ch, _numBytes);
#else
		::memset(_dst, _ch, _numBytes);
#endif // BX_CRT_NONE
	}

	DefaultAllocator::DefaultAllocator()
	{
	}

	DefaultAllocator::~DefaultAllocator()
	{
	}

	void* DefaultAllocator::realloc(void* _ptr, size_t _size, size_t _align, const char* _file, uint32_t _line)
	{
		if (0 == _size)
		{
			if (NULL != _ptr)
			{
				if (BX_CONFIG_ALLOCATOR_NATURAL_ALIGNMENT >= _align)
				{
					::free(_ptr);
					return NULL;
				}

#	if BX_COMPILER_MSVC
				BX_UNUSED(_file, _line);
				_aligned_free(_ptr);
#	else
				bx::alignedFree(this, _ptr, _align, _file, _line);
#	endif // BX_
			}

			return NULL;
		}
		else if (NULL == _ptr)
		{
			if (BX_CONFIG_ALLOCATOR_NATURAL_ALIGNMENT >= _align)
			{
				return ::malloc(_size);
			}

#	if BX_COMPILER_MSVC
			BX_UNUSED(_file, _line);
			return _aligned_malloc(_size, _align);
#	else
			return bx::alignedAlloc(this, _size, _align, _file, _line);
#	endif // BX_
		}

		if (BX_CONFIG_ALLOCATOR_NATURAL_ALIGNMENT >= _align)
		{
			return ::realloc(_ptr, _size);
		}

#	if BX_COMPILER_MSVC
		BX_UNUSED(_file, _line);
		return _aligned_realloc(_ptr, _size, _align);
#	else
		return bx::alignedRealloc(this, _ptr, _size, _align, _file, _line);
#	endif // BX_
	}
}

BX_PRAGMA_DIAGNOSTIC_IGNORED_MSVC(4244); // warning C4244: '=' : conversion from '' to '', possible loss of data

namespace
{
	#include "vs_nanovg_fill.bin.h"
	#include "fs_nanovg_fill.bin.h"

	static bgfx_vertex_layout_t s_nvgDecl;
	enum GLNVGshaderType
	{
		NSVG_SHADER_FILLGRAD,
		NSVG_SHADER_FILLIMG,
		NSVG_SHADER_SIMPLE,
		NSVG_SHADER_IMG
	};

	// These are additional flags on top of NVGimageFlags.
	enum NVGimageFlagsGL {
		NVG_IMAGE_NODELETE = 1<<16, // Do not delete GL texture handle.
	};

	struct GLNVGtexture
	{
		bgfx_texture_handle_t id;
		int width, height;
		int type;
		int flags;
	};

	struct GLNVGblend
	{
		uint64_t srcRGB;
		uint64_t dstRGB;
		uint64_t srcAlpha;
		uint64_t dstAlpha;
	};

	enum GLNVGcallType
	{
		GLNVG_FILL,
		GLNVG_CONVEXFILL,
		GLNVG_STROKE,
		GLNVG_TRIANGLES,
	};

	struct GLNVGcall
	{
		int type;
		int image;
		int pathOffset;
		int pathCount;
		int vertexOffset;
		int vertexCount;
		int uniformOffset;
		GLNVGblend blendFunc;
	};

	struct GLNVGpath
	{
		int fillOffset;
		int fillCount;
		int strokeOffset;
		int strokeCount;
	};

	struct GLNVGfragUniforms
	{
		float scissorMat[12]; // matrices are actually 3 vec4s
		float paintMat[12];
		NVGcolor innerCol;
		NVGcolor outerCol;

		// u_scissorExtScale
		float scissorExt[2];
		float scissorScale[2];

		// u_extentRadius
		float extent[2];
		float radius;

		// u_params
		float feather;
		float strokeMult;
		float texType;
		float type;
	};

	struct GLNVGcontext
	{
		bx::AllocatorI* m_allocator;

		bgfx_program_handle_t prog;
		bgfx_uniform_handle_t u_scissorMat;
		bgfx_uniform_handle_t u_paintMat;
		bgfx_uniform_handle_t u_innerCol;
		bgfx_uniform_handle_t u_outerCol;
		bgfx_uniform_handle_t u_viewSize;
		bgfx_uniform_handle_t u_scissorExtScale;
		bgfx_uniform_handle_t u_extentRadius;
		bgfx_uniform_handle_t u_params;
		bgfx_uniform_handle_t u_halfTexel;

		bgfx_uniform_handle_t s_tex;

		uint64_t state;
		bgfx_texture_handle_t th;
		bgfx_texture_handle_t texMissing;

		bgfx_transient_vertex_buffer_t tvb;
		uint8_t m_viewId;

		struct GLNVGtexture* textures;
		float view[2];
		int ntextures;
		int ctextures;
		int textureId;
		int vertBuf;
		int fragSize;
		int edgeAntiAlias;

		// Per frame buffers
		struct GLNVGcall* calls;
		int ccalls;
		int ncalls;
		struct GLNVGpath* paths;
		int cpaths;
		int npaths;
		struct NVGvertex* verts;
		int cverts;
		int nverts;
		unsigned char* uniforms;
		int cuniforms;
		int nuniforms;
	};

	bool bgfx_is_valid(bgfx_texture_handle_t& tex) {
		return tex.idx != BGFX_INVALID_HANDLE_IDX;
	}

	bool bgfx_is_valid(bgfx_uniform_handle_t& uhandle) {
		return uhandle.idx != BGFX_INVALID_HANDLE_IDX;
	}

	static struct GLNVGtexture* glnvg__allocTexture(struct GLNVGcontext* gl)
	{
		struct GLNVGtexture* tex = NULL;
		int i;

		for (i = 0; i < gl->ntextures; i++)
		{
			if (gl->textures[i].id.idx == BGFX_INVALID_HANDLE_IDX)
			{
				tex = &gl->textures[i];
				break;
			}
		}

		if (tex == NULL)
		{
			if (gl->ntextures+1 > gl->ctextures)
			{
				int old = gl->ctextures;
				gl->ctextures = (gl->ctextures == 0) ? 2 : gl->ctextures*2;
				gl->textures = (struct GLNVGtexture*)BX_REALLOC(gl->m_allocator, gl->textures, sizeof(struct GLNVGtexture)*gl->ctextures);
				bx::memSet(&gl->textures[old], 0xff, (gl->ctextures-old)*sizeof(struct GLNVGtexture) );

				if (gl->textures == NULL)
				{
					return NULL;
				}
			}
			tex = &gl->textures[gl->ntextures++];
		}

		bx::memSet(tex, 0, sizeof(*tex) );

		return tex;
	}

	static struct GLNVGtexture* glnvg__findTexture(struct GLNVGcontext* gl, int id)
	{
		int i;
		for (i = 0; i < gl->ntextures; i++)
		{
			if (gl->textures[i].id.idx == id)
			{
				return &gl->textures[i];
			}
		}

		return NULL;
	}

	static int glnvg__deleteTexture(struct GLNVGcontext* gl, int id)
	{
		for (int ii = 0; ii < gl->ntextures; ii++)
		{
			if (gl->textures[ii].id.idx == id)
			{
				if (bgfx_is_valid(gl->textures[ii].id)
					&& (gl->textures[ii].flags & NVG_IMAGE_NODELETE) == 0)
				{
					bgfx_destroy_texture(gl->textures[ii].id);
				}
				bx::memSet(&gl->textures[ii], 0, sizeof(gl->textures[ii]) );
				gl->textures[ii].id.idx = BGFX_INVALID_HANDLE_IDX;
				return 1;
			}
		}

		return 0;
	}

	static int nvgRenderCreate(void* _userPtr)
	{
		struct GLNVGcontext* gl = (struct GLNVGcontext*)_userPtr;

		const bgfx_memory_t* vs_nanovg_fill;
		const bgfx_memory_t* fs_nanovg_fill;

		switch (bgfx_get_renderer_type())
		{
		case BGFX_RENDERER_TYPE_DIRECT3D9:
			vs_nanovg_fill = bgfx_make_ref(vs_nanovg_fill_dx9, sizeof(vs_nanovg_fill_dx9));
			fs_nanovg_fill = bgfx_make_ref(fs_nanovg_fill_dx9, sizeof(fs_nanovg_fill_dx9));
			break;

		case BGFX_RENDERER_TYPE_DIRECT3D11:
		case BGFX_RENDERER_TYPE_DIRECT3D12:
			vs_nanovg_fill = bgfx_make_ref(vs_nanovg_fill_dx11, sizeof(vs_nanovg_fill_dx11));
			fs_nanovg_fill = bgfx_make_ref(fs_nanovg_fill_dx11, sizeof(fs_nanovg_fill_dx11));
			break;

		case BGFX_RENDERER_TYPE_VULKAN:
			vs_nanovg_fill = bgfx_make_ref(vs_nanovg_fill_spv, sizeof(vs_nanovg_fill_spv));
			fs_nanovg_fill = bgfx_make_ref(fs_nanovg_fill_spv, sizeof(fs_nanovg_fill_spv));
			break;

		case BGFX_RENDERER_TYPE_METAL:
			vs_nanovg_fill = bgfx_make_ref(vs_nanovg_fill_mtl, sizeof(vs_nanovg_fill_mtl));
			fs_nanovg_fill = bgfx_make_ref(fs_nanovg_fill_mtl, sizeof(fs_nanovg_fill_mtl));
			break;

		default:
			vs_nanovg_fill = bgfx_make_ref(vs_nanovg_fill_glsl, sizeof(vs_nanovg_fill_glsl));
			fs_nanovg_fill = bgfx_make_ref(fs_nanovg_fill_glsl, sizeof(fs_nanovg_fill_glsl));
			break;
		}

		gl->prog = bgfx_create_program(
			bgfx_create_shader(vs_nanovg_fill)
			, bgfx_create_shader(fs_nanovg_fill)
			, true
		);

		const bgfx_memory_t* mem = bgfx_alloc(4 * 4 * 4);
		uint32_t* bgra8 = (uint32_t*)mem->data;
		bx::memSet(bgra8, 0, 4*4*4);
		gl->texMissing = bgfx_create_texture_2d(4, 4, false, 1, BGFX_TEXTURE_FORMAT_BGRA8, 0, mem);

		gl->u_scissorMat      = bgfx_create_uniform("u_scissorMat", BGFX_UNIFORM_TYPE_MAT3, 1);
		gl->u_paintMat        = bgfx_create_uniform("u_paintMat", BGFX_UNIFORM_TYPE_MAT3, 1);
		gl->u_innerCol        = bgfx_create_uniform("u_innerCol", BGFX_UNIFORM_TYPE_VEC4, 1);
		gl->u_outerCol        = bgfx_create_uniform("u_outerCol", BGFX_UNIFORM_TYPE_VEC4, 1);
		gl->u_viewSize        = bgfx_create_uniform("u_viewSize", BGFX_UNIFORM_TYPE_VEC4, 1);
		gl->u_scissorExtScale = bgfx_create_uniform("u_scissorExtScale", BGFX_UNIFORM_TYPE_VEC4, 1);
		gl->u_extentRadius    = bgfx_create_uniform("u_extentRadius", BGFX_UNIFORM_TYPE_VEC4, 1);
		gl->u_params          = bgfx_create_uniform("u_params", BGFX_UNIFORM_TYPE_VEC4, 1);
		gl->s_tex             = bgfx_create_uniform("s_tex", BGFX_UNIFORM_TYPE_SAMPLER, 1);

		if (bgfx_get_renderer_type() == BGFX_RENDERER_TYPE_DIRECT3D9)
		{
			gl->u_halfTexel = bgfx_create_uniform("u_halfTexel", BGFX_UNIFORM_TYPE_VEC4, 1);
		}
		else
		{
			gl->u_halfTexel.idx = BGFX_INVALID_HANDLE_IDX;
		}

		bgfx_vertex_layout_begin(&s_nvgDecl, bgfx_get_renderer_type());
		bgfx_vertex_layout_add(&s_nvgDecl, BGFX_ATTRIB_POSITION, 2, BGFX_ATTRIB_TYPE_FLOAT, false, false);
		bgfx_vertex_layout_add(&s_nvgDecl, BGFX_ATTRIB_TEXCOORD0, 2, BGFX_ATTRIB_TYPE_FLOAT, false, false);
		bgfx_vertex_layout_end(&s_nvgDecl);

		int align = 16;
		gl->fragSize = sizeof(struct GLNVGfragUniforms) + align - sizeof(struct GLNVGfragUniforms) % align;

		return 1;
	}

	static int nvgRenderCreateTexture(
		void* _userPtr
		, int _type
		, int _width
		, int _height
		, int _flags
		, const unsigned char* _rgba
	)
	{
		struct GLNVGcontext* gl = (struct GLNVGcontext*)_userPtr;
		struct GLNVGtexture* tex = glnvg__allocTexture(gl);

		if (tex == NULL)
		{
			return 0;
		}

		tex->width  = _width;
		tex->height = _height;
		tex->type   = _type;
		tex->flags  = _flags;

		uint32_t bytesPerPixel = NVG_TEXTURE_RGBA == tex->type ? 4 : 1;
		uint32_t pitch = tex->width * bytesPerPixel;

		const bgfx_memory_t* mem = NULL;
		if (NULL != _rgba)
		{
			mem = bgfx_copy(_rgba, tex->height * pitch);
		}

		tex->id = bgfx_create_texture_2d(
			tex->width
			, tex->height
			, false
			, 1
			, NVG_TEXTURE_RGBA == _type ? BGFX_TEXTURE_FORMAT_RGBA8 : BGFX_TEXTURE_FORMAT_R8
			, BGFX_TEXTURE_NONE
			, NULL
		);

		if (NULL != mem)
		{
			bgfx_update_texture_2d(
				tex->id
				, 0
				, 0
				, 0
				, 0
				, tex->width
				, tex->height
				, mem
				, UINT16_MAX
			);
		}

		return bgfx_is_valid(tex->id) ? tex->id.idx : 0;
	}

	static int nvgRenderDeleteTexture(void* _userPtr, int image)
	{
		struct GLNVGcontext* gl = (struct GLNVGcontext*)_userPtr;
		return glnvg__deleteTexture(gl, image);
	}

	static int nvgRenderUpdateTexture(void* _userPtr, int image, int x, int y, int w, int h, const unsigned char* data)
	{
		struct GLNVGcontext* gl = (struct GLNVGcontext*)_userPtr;
		struct GLNVGtexture* tex = glnvg__findTexture(gl, image);
		if (tex == NULL)
		{
			return 0;
		}

		uint32_t bytesPerPixel = NVG_TEXTURE_RGBA == tex->type ? 4 : 1;
		uint32_t pitch = tex->width * bytesPerPixel;

		const bgfx_memory_t* mem = bgfx_alloc(w * h * bytesPerPixel);
		bx::gather(mem->data, data + y * pitch + x * bytesPerPixel, w * bytesPerPixel, h, pitch);

		bgfx_update_texture_2d(
			tex->id
			, 0
			, 0
			, x
			, y
			, w
			, h
			, mem
			, UINT16_MAX
		);

		return 1;
	}

	static int nvgRenderGetTextureSize(void* _userPtr, int image, int* w, int* h)
	{
		struct GLNVGcontext* gl = (struct GLNVGcontext*)_userPtr;
		struct GLNVGtexture* tex = glnvg__findTexture(gl, image);

		if (NULL == tex
			|| !bgfx_is_valid(tex->id))
		{
			return 0;
		}

		*w = tex->width;
		*h = tex->height;

		return 1;
	}

	static void glnvg__xformToMat3x4(float* m3, float* t)
	{
		m3[ 0] = t[0];
		m3[ 1] = t[1];
		m3[ 2] = 0.0f;
		m3[ 3] = 0.0f;
		m3[ 4] = t[2];
		m3[ 5] = t[3];
		m3[ 6] = 0.0f;
		m3[ 7] = 0.0f;
		m3[ 8] = t[4];
		m3[ 9] = t[5];
		m3[10] = 1.0f;
		m3[11] = 0.0f;
	}

	static NVGcolor glnvg__premulColor(NVGcolor c)
	{
		c.r *= c.a;
		c.g *= c.a;
		c.b *= c.a;
		return c;
	}

	static int glnvg__convertPaint(
		struct GLNVGcontext* gl
		, struct GLNVGfragUniforms* frag
		, struct NVGpaint* paint
		, struct NVGscissor* scissor
		, float width
		, float fringe
	)
	{
		struct GLNVGtexture* tex = NULL;
		float invxform[6] = {};

		bx::memSet(frag, 0, sizeof(*frag) );

		frag->innerCol = glnvg__premulColor(paint->innerColor);
		frag->outerCol = glnvg__premulColor(paint->outerColor);

		if (scissor->extent[0] < -0.5f || scissor->extent[1] < -0.5f)
		{
			bx::memSet(frag->scissorMat, 0, sizeof(frag->scissorMat) );
			frag->scissorExt[0] = 1.0f;
			frag->scissorExt[1] = 1.0f;
			frag->scissorScale[0] = 1.0f;
			frag->scissorScale[1] = 1.0f;
		}
		else
		{
			nvgTransformInverse(invxform, scissor->xform);
			glnvg__xformToMat3x4(frag->scissorMat, invxform);
			frag->scissorExt[0] = scissor->extent[0];
			frag->scissorExt[1] = scissor->extent[1];
			frag->scissorScale[0] = sqrtf(scissor->xform[0]*scissor->xform[0] + scissor->xform[2]*scissor->xform[2]) / fringe;
			frag->scissorScale[1] = sqrtf(scissor->xform[1]*scissor->xform[1] + scissor->xform[3]*scissor->xform[3]) / fringe;
		}
		bx::memCopy(frag->extent, paint->extent, sizeof(frag->extent) );
		frag->strokeMult = (width*0.5f + fringe*0.5f) / fringe;

		gl->th = gl->texMissing;
		if (paint->image != 0)
		{
			tex = glnvg__findTexture(gl, paint->image);
			if (tex == NULL)
			{
				return 0;
			}
			nvgTransformInverse(invxform, paint->xform);
			frag->type = NSVG_SHADER_FILLIMG;

			if (tex->type == NVG_TEXTURE_RGBA)
			{
				frag->texType = (tex->flags & NVG_IMAGE_PREMULTIPLIED) ? 0.0f : 1.0f;
			}
			else
			{
				frag->texType = 2.0f;
			}
			gl->th = tex->id;
		}
		else
		{
			frag->type = NSVG_SHADER_FILLGRAD;
			frag->radius  = paint->radius;
			frag->feather = paint->feather;
			nvgTransformInverse(invxform, paint->xform);
		}

		glnvg__xformToMat3x4(frag->paintMat, invxform);

		return 1;
	}

	static void glnvg__mat3(float* dst, float* src)
	{
		dst[0] = src[ 0];
		dst[1] = src[ 1];
		dst[2] = src[ 2];

		dst[3] = src[ 4];
		dst[4] = src[ 5];
		dst[5] = src[ 6];

		dst[6] = src[ 8];
		dst[7] = src[ 9];
		dst[8] = src[10];
	}

	static struct GLNVGfragUniforms* nvg__fragUniformPtr(struct GLNVGcontext* gl, int i)
	{
		return (struct GLNVGfragUniforms*)&gl->uniforms[i];
	}

	static void nvgRenderSetUniforms(struct GLNVGcontext* gl, int uniformOffset, int image)
	{
		struct GLNVGfragUniforms* frag = nvg__fragUniformPtr(gl, uniformOffset);
		float tmp[9]; // Maybe there's a way to get rid of this...
		glnvg__mat3(tmp, frag->scissorMat);
		bgfx_set_uniform(gl->u_scissorMat, tmp, 1);
		glnvg__mat3(tmp, frag->paintMat);
		bgfx_set_uniform(gl->u_paintMat, tmp, 1);

		bgfx_set_uniform(gl->u_innerCol,        frag->innerCol.rgba, 1);
		bgfx_set_uniform(gl->u_outerCol,        frag->outerCol.rgba, 1);
		bgfx_set_uniform(gl->u_scissorExtScale, &frag->scissorExt[0], 1);
		bgfx_set_uniform(gl->u_extentRadius,    &frag->extent[0], 1);
		bgfx_set_uniform(gl->u_params,          &frag->feather, 1);

		bgfx_texture_handle_t handle = gl->texMissing;

		if (image != 0)
		{
			struct GLNVGtexture* tex = glnvg__findTexture(gl, image);
			if (tex != NULL)
			{
				handle = tex->id;

				if (bgfx_is_valid(gl->u_halfTexel))
				{
					float halfTexel[4] = { 0.5f / tex->width, 0.5f / tex->height };
					bgfx_set_uniform(gl->u_halfTexel, halfTexel, 1);
				}
			}
		}

		gl->th = handle;
	}

	static void nvgRenderViewport(void* _userPtr, float width, float height, float devicePixelRatio)
	{
		struct GLNVGcontext* gl = (struct GLNVGcontext*)_userPtr;
		gl->view[0] = width;
		gl->view[1] = height;
		bgfx_set_view_rect(gl->m_viewId, 0, 0, width * devicePixelRatio, height * devicePixelRatio);
	}

	static void fan(uint32_t _start, uint32_t _count)
	{
		uint32_t numTris = _count-2;
		bgfx_transient_index_buffer_t tib;
		bgfx_alloc_transient_index_buffer(&tib, numTris*3, false);
		uint16_t* data = (uint16_t*)tib.data;
		for (uint32_t ii = 0; ii < numTris; ++ii)
		{
			data[ii*3+0] = _start;
			data[ii*3+1] = _start + ii + 1;
			data[ii*3+2] = _start + ii + 2;
		}

		bgfx_set_transient_index_buffer(&tib, 0, UINT32_MAX);
	}

	static void glnvg__fill(struct GLNVGcontext* gl, struct GLNVGcall* call)
	{
		struct GLNVGpath* paths = &gl->paths[call->pathOffset];
		int i, npaths = call->pathCount;

		// set bindpoint for solid loc
		nvgRenderSetUniforms(gl, call->uniformOffset, 0);

		for (i = 0; i < npaths; i++)
		{
			if (2 < paths[i].fillCount)
			{
				bgfx_set_state(0, 0);
				bgfx_set_stencil(0
					| BGFX_STENCIL_TEST_ALWAYS
					| BGFX_STENCIL_FUNC_RMASK(0xff)
					| BGFX_STENCIL_OP_FAIL_S_KEEP
					| BGFX_STENCIL_OP_FAIL_Z_KEEP
					| BGFX_STENCIL_OP_PASS_Z_INCR
					, 0
					| BGFX_STENCIL_TEST_ALWAYS
					| BGFX_STENCIL_FUNC_RMASK(0xff)
					| BGFX_STENCIL_OP_FAIL_S_KEEP
					| BGFX_STENCIL_OP_FAIL_Z_KEEP
					| BGFX_STENCIL_OP_PASS_Z_DECR
				);
				bgfx_set_transient_vertex_buffer(0, &gl->tvb, 0, UINT32_MAX);
				bgfx_set_texture(0, gl->s_tex, gl->th, UINT32_MAX);
				fan(paths[i].fillOffset, paths[i].fillCount);
				bgfx_submit(gl->m_viewId, gl->prog, 0, BGFX_DISCARD_ALL);
			}
		}

		// Draw aliased off-pixels
		nvgRenderSetUniforms(gl, call->uniformOffset + gl->fragSize, call->image);

		if (gl->edgeAntiAlias)
		{
			// Draw fringes
			for (i = 0; i < npaths; i++)
			{
				bgfx_set_state(gl->state
					| BGFX_STATE_PT_TRISTRIP
					, 0);
				bgfx_set_stencil(0
					| BGFX_STENCIL_TEST_EQUAL
					| BGFX_STENCIL_FUNC_RMASK(0xff)
					| BGFX_STENCIL_OP_FAIL_S_KEEP
					| BGFX_STENCIL_OP_FAIL_Z_KEEP
					| BGFX_STENCIL_OP_PASS_Z_KEEP
					, 0
					| BGFX_STENCIL_TEST_ALWAYS
					| BGFX_STENCIL_FUNC_RMASK(0xff)
					| BGFX_STENCIL_OP_FAIL_S_KEEP
					| BGFX_STENCIL_OP_FAIL_Z_KEEP
					| BGFX_STENCIL_OP_PASS_Z_DECR
				);
				bgfx_set_transient_vertex_buffer(0, &gl->tvb, paths[i].strokeOffset, paths[i].strokeCount);
				bgfx_set_texture(0, gl->s_tex, gl->th, UINT32_MAX);
				bgfx_submit(gl->m_viewId, gl->prog, 0, BGFX_DISCARD_ALL);
			}
		}

		// Draw fill
		bgfx_set_state(gl->state, 0);
		bgfx_set_transient_vertex_buffer(0, &gl->tvb, call->vertexOffset, call->vertexCount);
		bgfx_set_texture(0, gl->s_tex, gl->th, UINT32_MAX);
		bgfx_set_stencil(0
			| BGFX_STENCIL_TEST_NOTEQUAL
			| BGFX_STENCIL_FUNC_RMASK(0xff)
			| BGFX_STENCIL_OP_FAIL_S_ZERO
			| BGFX_STENCIL_OP_FAIL_Z_ZERO
			| BGFX_STENCIL_OP_PASS_Z_ZERO
			, 0
			| BGFX_STENCIL_TEST_NOTEQUAL
			| BGFX_STENCIL_FUNC_RMASK(0xff)
			| BGFX_STENCIL_OP_FAIL_S_ZERO
			| BGFX_STENCIL_OP_FAIL_Z_ZERO
			| BGFX_STENCIL_OP_PASS_Z_ZERO
		);
		bgfx_submit(gl->m_viewId, gl->prog, 0, BGFX_DISCARD_ALL);
	}

	static void glnvg__convexFill(struct GLNVGcontext* gl, struct GLNVGcall* call)
	{
		struct GLNVGpath* paths = &gl->paths[call->pathOffset];
		int i, npaths = call->pathCount;

		nvgRenderSetUniforms(gl, call->uniformOffset, call->image);

		for (i = 0; i < npaths; i++)
		{
			if (paths[i].fillCount == 0) continue;
			bgfx_set_state(gl->state, 0);
			bgfx_set_transient_vertex_buffer(0, &gl->tvb, 0, UINT32_MAX);
			bgfx_set_texture(0, gl->s_tex, gl->th, UINT32_MAX);
			fan(paths[i].fillOffset, paths[i].fillCount);
			bgfx_submit(gl->m_viewId, gl->prog, 0, BGFX_DISCARD_ALL);
		}

		if (gl->edgeAntiAlias)
		{
			// Draw fringes
			for (i = 0; i < npaths; i++)
			{
				bgfx_set_state(gl->state
					| BGFX_STATE_PT_TRISTRIP
					, 0);
				bgfx_set_transient_vertex_buffer(0, &gl->tvb, paths[i].strokeOffset, paths[i].strokeCount);
				bgfx_set_texture(0, gl->s_tex, gl->th, UINT32_MAX);
				bgfx_submit(gl->m_viewId, gl->prog, 0, BGFX_DISCARD_ALL);
			}
		}
	}

	static void glnvg__stroke(struct GLNVGcontext* gl, struct GLNVGcall* call)
	{
		struct GLNVGpath* paths = &gl->paths[call->pathOffset];
		int npaths = call->pathCount, i;

		nvgRenderSetUniforms(gl, call->uniformOffset, call->image);

		// Draw Strokes
		for (i = 0; i < npaths; i++)
		{
			bgfx_set_state(gl->state
				| BGFX_STATE_PT_TRISTRIP
				, 0);
			bgfx_set_transient_vertex_buffer(0, &gl->tvb, paths[i].strokeOffset, paths[i].strokeCount);
			bgfx_set_texture(0, gl->s_tex, gl->th, UINT32_MAX);
			bgfx_submit(gl->m_viewId, gl->prog, 0, BGFX_DISCARD_ALL);
		}
	}

	static void glnvg__triangles(struct GLNVGcontext* gl, struct GLNVGcall* call)
	{
		if (3 <= call->vertexCount)
		{
			nvgRenderSetUniforms(gl, call->uniformOffset, call->image);

			bgfx_set_state(gl->state, 0);
			bgfx_set_transient_vertex_buffer(0, &gl->tvb, call->vertexOffset, call->vertexCount);
			bgfx_set_texture(0, gl->s_tex, gl->th, UINT32_MAX);
			bgfx_submit(gl->m_viewId, gl->prog, 0, BGFX_DISCARD_ALL);
		}
	}

	static const uint64_t s_blend[] =
	{
		BGFX_STATE_BLEND_ZERO,
		BGFX_STATE_BLEND_ONE,
		BGFX_STATE_BLEND_SRC_COLOR,
		BGFX_STATE_BLEND_INV_SRC_COLOR,
		BGFX_STATE_BLEND_DST_COLOR,
		BGFX_STATE_BLEND_INV_DST_COLOR,
		BGFX_STATE_BLEND_SRC_ALPHA,
		BGFX_STATE_BLEND_INV_SRC_ALPHA,
		BGFX_STATE_BLEND_DST_ALPHA,
		BGFX_STATE_BLEND_INV_DST_ALPHA,
		BGFX_STATE_BLEND_SRC_ALPHA_SAT,
	};

	static uint64_t glnvg_convertBlendFuncFactor(int factor)
	{
		const uint32_t numtz = bx::uint32_cnttz(factor);
		const uint32_t idx   = bx::uint32_min(numtz, BX_COUNTOF(s_blend)-1);
		return s_blend[idx];
	}

	static GLNVGblend glnvg__blendCompositeOperation(NVGcompositeOperationState op)
	{
		GLNVGblend blend;
		blend.srcRGB = glnvg_convertBlendFuncFactor(op.srcRGB);
		blend.dstRGB = glnvg_convertBlendFuncFactor(op.dstRGB);
		blend.srcAlpha = glnvg_convertBlendFuncFactor(op.srcAlpha);
		blend.dstAlpha = glnvg_convertBlendFuncFactor(op.dstAlpha);
		if (blend.srcRGB == BGFX_STATE_NONE || blend.dstRGB == BGFX_STATE_NONE || blend.srcAlpha == BGFX_STATE_NONE || blend.dstAlpha == BGFX_STATE_NONE)
		{
			blend.srcRGB = BGFX_STATE_BLEND_ONE;
			blend.dstRGB = BGFX_STATE_BLEND_INV_SRC_ALPHA;
			blend.srcAlpha = BGFX_STATE_BLEND_ONE;
			blend.dstAlpha = BGFX_STATE_BLEND_INV_SRC_ALPHA;
		}
		return blend;
	}

	static void nvgRenderFlush(void* _userPtr)
	{
		struct GLNVGcontext* gl = (struct GLNVGcontext*)_userPtr;

		if (gl->ncalls > 0)
		{
			bgfx_alloc_transient_vertex_buffer(&gl->tvb, gl->nverts, &s_nvgDecl);

			int allocated = gl->tvb.size/gl->tvb.stride;

			if (allocated < gl->nverts)
			{
				gl->nverts = allocated;
				BX_WARN(true, "Vertex number truncated due to transient vertex buffer overflow");
			}

			bx::memCopy(gl->tvb.data, gl->verts, gl->nverts * sizeof(struct NVGvertex) );

			bgfx_set_uniform(gl->u_viewSize, gl->view, 1);

			for (uint32_t ii = 0, num = gl->ncalls; ii < num; ++ii)
			{
				struct GLNVGcall* call = &gl->calls[ii];
				const GLNVGblend* blend = &call->blendFunc;
				gl->state = BGFX_STATE_BLEND_FUNC_SEPARATE(blend->srcRGB, blend->dstRGB, blend->srcAlpha, blend->dstAlpha)
					| BGFX_STATE_WRITE_RGB
					| BGFX_STATE_WRITE_A
					;
				switch (call->type)
				{
				case GLNVG_FILL:
					glnvg__fill(gl, call);
					break;

				case GLNVG_CONVEXFILL:
					glnvg__convexFill(gl, call);
					break;

				case GLNVG_STROKE:
					glnvg__stroke(gl, call);
					break;

				case GLNVG_TRIANGLES:
					glnvg__triangles(gl, call);
					break;
				}
			}
		}

		// Reset calls
		gl->nverts    = 0;
		gl->npaths    = 0;
		gl->ncalls    = 0;
		gl->nuniforms = 0;
	}

	static int glnvg__maxVertCount(const struct NVGpath* paths, int npaths)
	{
		int i, count = 0;
		for (i = 0; i < npaths; i++)
		{
			count += paths[i].nfill;
			count += paths[i].nstroke;
		}
		return count;
	}

	static int glnvg__maxi(int a, int b) { return a > b ? a : b; }

	static struct GLNVGcall* glnvg__allocCall(struct GLNVGcontext* gl)
	{
		struct GLNVGcall* ret = NULL;
		if (gl->ncalls+1 > gl->ccalls)
		{
			gl->ccalls = gl->ccalls == 0 ? 32 : gl->ccalls * 2;
			gl->calls = (struct GLNVGcall*)BX_REALLOC(gl->m_allocator, gl->calls, sizeof(struct GLNVGcall) * gl->ccalls);
		}
		ret = &gl->calls[gl->ncalls++];
		bx::memSet(ret, 0, sizeof(struct GLNVGcall) );
		return ret;
	}

	static int glnvg__allocPaths(struct GLNVGcontext* gl, int n)
	{
		int ret = 0;
		if (gl->npaths + n > gl->cpaths) {
			GLNVGpath* paths;
			int cpaths = glnvg__maxi(gl->npaths + n, 128) + gl->cpaths / 2; // 1.5x Overallocate
			paths = (GLNVGpath*)BX_REALLOC(gl->m_allocator, gl->paths, sizeof(GLNVGpath) * cpaths);
			if (paths == NULL) return -1;
			gl->paths = paths;
			gl->cpaths = cpaths;
		}
		ret = gl->npaths;
		gl->npaths += n;
		return ret;
	}

	static int glnvg__allocVerts(GLNVGcontext* gl, int n)
	{
		int ret = 0;
		if (gl->nverts + n > gl->cverts)
		{
			NVGvertex* verts;
			int cverts = glnvg__maxi(gl->nverts + n, 4096) + gl->cverts/2; // 1.5x Overallocate
			verts = (NVGvertex*)BX_REALLOC(gl->m_allocator, gl->verts, sizeof(NVGvertex) * cverts);
			if (verts == NULL) return -1;
			gl->verts = verts;
			gl->cverts = cverts;
		}
		ret = gl->nverts;
		gl->nverts += n;
		return ret;
	}

	static int glnvg__allocFragUniforms(struct GLNVGcontext* gl, int n)
	{
		int ret = 0, structSize = gl->fragSize;
		if (gl->nuniforms+n > gl->cuniforms)
		{
			gl->cuniforms = gl->cuniforms == 0 ? glnvg__maxi(n, 32) : gl->cuniforms * 2;
			gl->uniforms = (unsigned char*)BX_REALLOC(gl->m_allocator, gl->uniforms, gl->cuniforms * structSize);
		}
		ret = gl->nuniforms * structSize;
		gl->nuniforms += n;
		return ret;
	}

	static void glnvg__vset(struct NVGvertex* vtx, float x, float y, float u, float v)
	{
		vtx->x = x;
		vtx->y = y;
		vtx->u = u;
		vtx->v = v;
	}

	static void nvgRenderFill(
		void* _userPtr
		, NVGpaint* paint
		, NVGcompositeOperationState compositeOperation
		, NVGscissor* scissor
		, float fringe
		, const float* bounds
		, const NVGpath* paths
		, int npaths
	)
	{
		struct GLNVGcontext* gl = (struct GLNVGcontext*)_userPtr;

		struct GLNVGcall* call = glnvg__allocCall(gl);
		struct NVGvertex* quad;
		struct GLNVGfragUniforms* frag;
		int i, maxverts, offset;

		call->type = GLNVG_FILL;
		call->pathOffset = glnvg__allocPaths(gl, npaths);
		call->pathCount = npaths;
		call->image = paint->image;
		call->blendFunc = glnvg__blendCompositeOperation(compositeOperation);

		if (npaths == 1 && paths[0].convex)
		{
			call->type = GLNVG_CONVEXFILL;
		}

		// Allocate vertices for all the paths.
		maxverts = glnvg__maxVertCount(paths, npaths) + 6;
		offset = glnvg__allocVerts(gl, maxverts);

		for (i = 0; i < npaths; i++)
		{
			struct GLNVGpath* copy = &gl->paths[call->pathOffset + i];
			const struct NVGpath* path = &paths[i];
			bx::memSet(copy, 0, sizeof(struct GLNVGpath) );
			if (path->nfill > 0)
			{
				copy->fillOffset = offset;
				copy->fillCount = path->nfill;
				bx::memCopy(&gl->verts[offset], path->fill, sizeof(struct NVGvertex) * path->nfill);
				offset += path->nfill;
			}

			if (path->nstroke > 0)
			{
				copy->strokeOffset = offset;
				copy->strokeCount = path->nstroke;
				bx::memCopy(&gl->verts[offset], path->stroke, sizeof(struct NVGvertex) * path->nstroke);
				offset += path->nstroke;
			}
		}

		// Quad
		call->vertexOffset = offset;
		call->vertexCount = 6;
		quad = &gl->verts[call->vertexOffset];
		glnvg__vset(&quad[0], bounds[0], bounds[3], 0.5f, 1.0f);
		glnvg__vset(&quad[1], bounds[2], bounds[3], 0.5f, 1.0f);
		glnvg__vset(&quad[2], bounds[2], bounds[1], 0.5f, 1.0f);

		glnvg__vset(&quad[3], bounds[0], bounds[3], 0.5f, 1.0f);
		glnvg__vset(&quad[4], bounds[2], bounds[1], 0.5f, 1.0f);
		glnvg__vset(&quad[5], bounds[0], bounds[1], 0.5f, 1.0f);

		// Setup uniforms for draw calls
		if (call->type == GLNVG_FILL)
		{
			call->uniformOffset = glnvg__allocFragUniforms(gl, 2);
			// Simple shader for stencil
			frag = nvg__fragUniformPtr(gl, call->uniformOffset);
			bx::memSet(frag, 0, sizeof(*frag) );
			frag->type = NSVG_SHADER_SIMPLE;
			// Fill shader
			glnvg__convertPaint(gl, nvg__fragUniformPtr(gl, call->uniformOffset + gl->fragSize), paint, scissor, fringe, fringe);
		}
		else
		{
			call->uniformOffset = glnvg__allocFragUniforms(gl, 1);
			// Fill shader
			glnvg__convertPaint(gl, nvg__fragUniformPtr(gl, call->uniformOffset), paint, scissor, fringe, fringe);
		}
	}

	static void nvgRenderStroke(
		void* _userPtr
		, struct NVGpaint* paint
		, NVGcompositeOperationState compositeOperation
		, struct NVGscissor* scissor
		, float fringe
		, float strokeWidth
		, const struct NVGpath* paths
		, int npaths
	)
	{
		struct GLNVGcontext* gl = (struct GLNVGcontext*)_userPtr;

		struct GLNVGcall* call = glnvg__allocCall(gl);
		int i, maxverts, offset;

		call->type = GLNVG_STROKE;
		call->pathOffset = glnvg__allocPaths(gl, npaths);
		call->pathCount = npaths;
		call->image = paint->image;
		call->blendFunc = glnvg__blendCompositeOperation(compositeOperation);

		// Allocate vertices for all the paths.
		maxverts = glnvg__maxVertCount(paths, npaths);
		offset = glnvg__allocVerts(gl, maxverts);

		for (i = 0; i < npaths; i++)
		{
			struct GLNVGpath* copy = &gl->paths[call->pathOffset + i];
			const struct NVGpath* path = &paths[i];
			bx::memSet(copy, 0, sizeof(struct GLNVGpath) );
			if (path->nstroke)
			{
				copy->strokeOffset = offset;
				copy->strokeCount = path->nstroke;
				bx::memCopy(&gl->verts[offset], path->stroke, sizeof(struct NVGvertex) * path->nstroke);
				offset += path->nstroke;
			}
		}

		// Fill shader
		call->uniformOffset = glnvg__allocFragUniforms(gl, 1);
		glnvg__convertPaint(gl, nvg__fragUniformPtr(gl, call->uniformOffset), paint, scissor, strokeWidth, fringe);
	}

	static void nvgRenderTriangles(void* _userPtr, struct NVGpaint* paint, NVGcompositeOperationState compositeOperation, struct NVGscissor* scissor,
		const struct NVGvertex* verts, int nverts)
	{
		struct GLNVGcontext* gl = (struct GLNVGcontext*)_userPtr;
		struct GLNVGcall* call = glnvg__allocCall(gl);
		struct GLNVGfragUniforms* frag;

		call->type = GLNVG_TRIANGLES;
		call->image = paint->image;
		call->blendFunc = glnvg__blendCompositeOperation(compositeOperation);

		// Allocate vertices for all the paths.
		call->vertexOffset = glnvg__allocVerts(gl, nverts);
		call->vertexCount = nverts;
		bx::memCopy(&gl->verts[call->vertexOffset], verts, sizeof(struct NVGvertex) * nverts);

		// Fill shader
		call->uniformOffset = glnvg__allocFragUniforms(gl, 1);
		frag = nvg__fragUniformPtr(gl, call->uniformOffset);
		glnvg__convertPaint(gl, frag, paint, scissor, 1.0f, 1.0f);
		frag->type = NSVG_SHADER_IMG;
	}

	static void nvgRenderDelete(void* _userPtr)
	{
		struct GLNVGcontext* gl = (struct GLNVGcontext*)_userPtr;

		if (gl == NULL)
		{
			return;
		}

		bgfx_destroy_program(gl->prog);
		bgfx_destroy_texture(gl->texMissing);

		bgfx_destroy_uniform(gl->u_scissorMat);
		bgfx_destroy_uniform(gl->u_paintMat);
		bgfx_destroy_uniform(gl->u_innerCol);
		bgfx_destroy_uniform(gl->u_outerCol);
		bgfx_destroy_uniform(gl->u_viewSize);
		bgfx_destroy_uniform(gl->u_scissorExtScale);
		bgfx_destroy_uniform(gl->u_extentRadius);
		bgfx_destroy_uniform(gl->u_params);
		bgfx_destroy_uniform(gl->s_tex);

		if (bgfx_is_valid(gl->u_halfTexel) )
		{
			bgfx_destroy_uniform(gl->u_halfTexel);
		}

		for (uint32_t ii = 0, num = gl->ntextures; ii < num; ++ii)
		{
			if (bgfx_is_valid(gl->textures[ii].id)
				&& (gl->textures[ii].flags & NVG_IMAGE_NODELETE) == 0)
			{
				bgfx_destroy_texture(gl->textures[ii].id);
			}
		}

		BX_FREE(gl->m_allocator, gl->uniforms);
		BX_FREE(gl->m_allocator, gl->verts);
		BX_FREE(gl->m_allocator, gl->paths);
		BX_FREE(gl->m_allocator, gl->calls);
		BX_FREE(gl->m_allocator, gl->textures);
		BX_FREE(gl->m_allocator, gl);
	}

} // namespace

NVGcontext* nvgCreate(int32_t edgeaa, unsigned char _viewId, bx::AllocatorI* _allocator)
{
	if (NULL == _allocator)
	{
		static bx::DefaultAllocator allocator;
		_allocator = &allocator;
	}

	struct NVGparams params;
	struct NVGcontext* ctx = NULL;
	struct GLNVGcontext* gl = (struct GLNVGcontext*)BX_ALLOC(_allocator, sizeof(struct GLNVGcontext) );
	if (gl == NULL)
	{
		goto error;
	}

	bx::memSet(gl, 0, sizeof(struct GLNVGcontext));

	bx::memSet(&params, 0, sizeof(params));
	params.renderCreate = nvgRenderCreate;
	params.renderCreateTexture = nvgRenderCreateTexture;
	params.renderDeleteTexture = nvgRenderDeleteTexture;
	params.renderUpdateTexture = nvgRenderUpdateTexture;
	params.renderGetTextureSize = nvgRenderGetTextureSize;
	params.renderViewport = nvgRenderViewport;
	params.renderFlush = nvgRenderFlush;
	params.renderFill = nvgRenderFill;
	params.renderStroke = nvgRenderStroke;
	params.renderTriangles = nvgRenderTriangles;
	params.renderDelete = nvgRenderDelete;
	params.userPtr = gl;
	params.edgeAntiAlias = edgeaa;

	gl->m_allocator = _allocator;
	gl->edgeAntiAlias = edgeaa;
	gl->m_viewId = uint8_t(_viewId);

	ctx = nvgCreateInternal(&params);
	if (ctx == NULL) goto error;

	return ctx;

error:
	// 'gl' is freed by nvgDeleteInternal.
	if (ctx != NULL)
	{
		nvgDeleteInternal(ctx);
	}

	return NULL;
}

NVGcontext* nvgCreate(unsigned int _edgeaa, unsigned char _viewId) {
	return nvgCreate(_edgeaa, _viewId, NULL);
}

void nvgDelete(NVGcontext* _ctx)
{
	nvgDeleteInternal(_ctx);
}

void nvgSetViewId(NVGcontext* _ctx, unsigned char _viewId)
{
	struct NVGparams* params = nvgInternalParams(_ctx);
	struct GLNVGcontext* gl = (struct GLNVGcontext*)params->userPtr;
	gl->m_viewId = _viewId;
}

uint16_t nvgGetViewId(struct NVGcontext* _ctx)
{
	struct NVGparams* params = nvgInternalParams(_ctx);
	struct GLNVGcontext* gl = (struct GLNVGcontext*)params->userPtr;
	return gl->m_viewId;
}

bgfx_texture_handle_t nvglImageHandle(NVGcontext* _ctx, int32_t _image)
{
	GLNVGcontext* gl = (GLNVGcontext*)nvgInternalParams(_ctx)->userPtr;
	GLNVGtexture* tex = glnvg__findTexture(gl, _image);
	return tex->id;
}
