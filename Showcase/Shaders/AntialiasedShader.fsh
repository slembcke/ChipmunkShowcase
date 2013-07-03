/* Copyright (c) 2012 Scott Lembcke and Howling Moon Software
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#extension GL_OES_standard_derivatives : enable

varying mediump vec4 frag_color;
varying mediump vec2 frag_texcoord;

uniform sampler2D texture;

void main()
{
//	gl_FragColor = texture2D(texture, frag_texcoord).a;
	gl_FragColor = texture2D(texture, frag_texcoord);
//#if defined GL_OES_standard_derivatives
//	gl_FragColor = frag_color*smoothstep(0.0, length(fwidth(frag_texcoord)), 1.0 - length(frag_texcoord));
//#else
//	gl_FragColor = frag_color*step(0.0, 1.0 - length(frag_texcoord));//*texture2D(texture, frag_texcoord).a;
//#endif
}
