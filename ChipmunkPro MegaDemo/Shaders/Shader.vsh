//
//  Shader.vsh
//  ChipmunkPro MegaDemo
//
//  Created by Scott Lembcke on 12/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

attribute vec4 position;

varying lowp vec4 colorVarying;

uniform mat4 modelViewProjectionMatrix;

void main()
{
    colorVarying = vec4(1,0,0,1);
    
    gl_Position = modelViewProjectionMatrix * position;
}
