//
//  Shader.fsh
//  ChipmunkPro MegaDemo
//
//  Created by Scott Lembcke on 12/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

varying lowp vec4 frag_color;
varying lowp vec2 frag_texcoord;

uniform lowp float fwidth;

void main()
{
	gl_FragColor = frag_color*smoothstep(0.0, fwidth, 1.0 - length(frag_texcoord));
}
