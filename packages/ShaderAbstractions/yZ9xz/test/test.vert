#version 300 es
precision mediump int;
precision mediump float;
precision mediump sampler2D;
precision mediump sampler3D;

// Instance inputs: 
in vec3 position;
vec3 get_position(){return position;}
in vec3 normals;
vec3 get_normals(){return normals;}

// Uniforms: 
uniform mat4 model;
mat4 get_model(){return model;}
uniform mat4 view;
mat4 get_view(){return view;}
uniform mat4 projection;
mat4 get_projection(){return projection;}




// Per instance attributes: 
in vec3 positions;
vec3 get_positions(){return positions;}

void main(){}

