#version 300 es
precision mediump int;
precision mediump float;
precision mediump sampler2D;
precision mediump sampler3D;

out vec4 fragment_color;

// Uniforms: 
uniform mat4 model;
mat4 get_model(){return model;}
uniform mat4 view;
mat4 get_view(){return view;}
uniform mat4 projection;
mat4 get_projection(){return projection;}

void main(){}
