#extension GL_OES_standard_derivatives : enable

varying mediump vec4 frag_color;
varying mediump vec2 frag_texcoord;

//uniform sampler2D texture;

void main()
{
#if defined GL_OES_standard_derivatives
	gl_FragColor = frag_color*smoothstep(0.0, length(fwidth(frag_texcoord)), 1.0 - length(frag_texcoord));
#else
	gl_FragColor = frag_color*step(0.0, 1.0 - length(frag_texcoord));//*texture2D(texture, frag_texcoord).a;
#endif
}
