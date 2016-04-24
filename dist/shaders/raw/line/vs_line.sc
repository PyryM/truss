$input a_position, a_normal, a_color0
$output v_wpos

/* Adapted from https://github.com/mattdesl/webgl-lines
 * The MIT License (MIT) 
 * Copyright (c) 2015 Matt DesLauriers
 * Modifications to work with bgfx copyright 2015 Pyry Matikainen

 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense, 
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:

 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.

 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */

#include "../common/common.sh"

uniform vec4 u_thickness;

void main() {
  float aspect = u_viewRect.z / u_viewRect.w;
  vec2 aspectVec = vec2(aspect, 1.0);
  mat4 projViewModel = u_modelViewProj; //projection * view * model;
  vec4 previousProjected = mul(projViewModel, vec4(a_normal, 1.0));
  vec4 currentProjected = mul(projViewModel, vec4(a_position, 1.0));
  vec4 nextProjected = mul(projViewModel, vec4(a_color0.xyz, 1.0));

  //get 2D screen space with W divide and aspect correction
  vec2 currentScreen = currentProjected.xy / currentProjected.w * aspectVec;
  vec2 previousScreen = previousProjected.xy / previousProjected.w * aspectVec;
  vec2 nextScreen = nextProjected.xy / nextProjected.w * aspectVec;

  float len = u_thickness.x;
  float orientation = a_color0.w;

  //starting point uses (next - current)
  vec2 dir = vec2(0.0, 0.0);
  if (currentScreen.x == previousScreen.x && currentScreen.y == previousScreen.y) {
    dir = normalize(nextScreen - currentScreen);
  } 
  //ending point and middle uses (current - previous)
  else {
    dir = normalize(currentScreen - previousScreen);
  }

  vec2 normal = vec2(-dir.y, dir.x);
  normal *= len/2.0;
  normal.x /= aspect;

  v_wpos = currentProjected.xyz;

  vec4 offset = vec4(normal * orientation, 0.0, 0.0);
  gl_Position = currentProjected + offset;
}