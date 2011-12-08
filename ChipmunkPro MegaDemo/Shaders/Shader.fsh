varying lowp vec4 frag_color;
varying lowp vec2 frag_texcoord;

uniform sampler2D texture;

void main()
{
	gl_FragColor = frag_color;//frag_color*texture2D(texture, frag_texcoord).a;
}
