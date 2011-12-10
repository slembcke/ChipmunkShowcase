#extension GL_OES_standard_derivatives : enable

varying mediump vec4 frag_color;
varying mediump vec2 frag_texcoord;

//uniform sampler2D texture;

void main()
{
#if GL_OES_standard_derivatives
	gl_FragColor = frag_color*smoothstep(0.0, length(fwidth(frag_texcoord)), 1.0 - length(frag_texcoord));
#else
	gl_FragColor = frag_color;//*texture2D(texture, frag_texcoord).a;
#endif
}
