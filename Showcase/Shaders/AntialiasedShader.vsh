uniform mediump mat4 projection;

attribute mediump vec4 position;
attribute mediump vec2 texcoord;
attribute mediump vec4 color;

varying mediump vec4 frag_color;
varying mediump vec2 frag_texcoord;

void main()
{
    frag_color = color;
    frag_texcoord = texcoord;//*0.5 + 0.5;
    
    gl_Position = projection*position;
}
