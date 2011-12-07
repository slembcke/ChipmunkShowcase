//
//  Shader.vsh
//  ChipmunkPro MegaDemo
//
//  Created by Scott Lembcke on 12/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

attribute vec4 position;
attribute vec4 color;

varying lowp vec4 frag_color;

uniform mat4 modelViewProjectionMatrix;

void main()
{
    frag_color = color;
    
    gl_Position = modelViewProjectionMatrix * position;
}
