//
//  Shader.vsh
//  ChipmunkPro MegaDemo
//
//  Created by Scott Lembcke on 12/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

attribute vec4 position;
attribute vec2 texcoord;
attribute vec4 color;

varying lowp vec4 frag_color;
varying lowp vec2 frag_texcoord;

uniform mat4 modelViewProjectionMatrix;

void main()
{
    frag_color = color;
    frag_texcoord = texcoord;
    
    gl_Position = modelViewProjectionMatrix * position;
}
