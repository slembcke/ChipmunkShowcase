uniform mat4 projection;

attribute vec4 position;
attribute vec2 texcoord;
attribute vec4 color;

varying lowp vec4 frag_color;
varying lowp vec2 frag_texcoord;

void main()
{
    frag_color = color;
    frag_texcoord = texcoord;//*0.5 + 0.5;
    
    gl_Position = projection*position;
}
