#extension GL_OES_standard_derivatives : enable

varying lowp vec4 frag_color;
varying lowp vec2 frag_texcoord;

uniform sampler2D texture;

void main()
{
#if GL_OES_standard_derivatives && 1
	gl_FragColor = frag_color*smoothstep(0.0, length(fwidth(frag_texcoord)), 1.0 - length(frag_texcoord));
#else
	gl_FragColor = frag_color;//*texture2D(texture, frag_texcoord).a;
#endif
}
