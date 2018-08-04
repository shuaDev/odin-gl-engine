package workbench

SHADER_RGBA_VERT ::
`
#version 330 core

// from vbo
layout(location = 0) in vec2 vbo_vertex_position;
layout(location = 1) in vec2 vbo_tex_coord;
layout(location = 2) in vec4 vbo_color;

out vec4 desired_color;

uniform mat4 transform;

void main() {
    gl_Position = transform * vec4(vbo_vertex_position, 0, 1);
    desired_color = vbo_color;
}
`;

SHADER_RGBA_FRAG ::
`
#version 330 core

in vec4 desired_color;

out vec4 color;

void main() {
    color = desired_color;
}
`;

SHADER_TEXTURE_VERT ::
`
#version 330 core

// from vbo
layout(location = 0) in vec2 vbo_vertex_position;
layout(location = 1) in vec2 vbo_tex_coord;
layout(location = 2) in vec4 vbo_color;

out vec2 tex_coord;
out vec4 desired_color;

uniform mat4 transform;

void main() {
    gl_Position = transform * vec4(vbo_vertex_position, 0, 1);
    tex_coord = vbo_tex_coord;
    desired_color = vbo_color;
}
`;

SHADER_TEXTURE_FRAG ::
`
#version 330 core

in vec2 tex_coord;
in vec4 desired_color;

uniform sampler2D atlas_texture;

out vec4 color;

void main() {
    color = texture(atlas_texture, tex_coord) * desired_color;
}
`;

SHADER_TEXT_VERT ::
`
#version 330 core

// from vbo
layout(location = 0) in vec2 vbo_vertex_position;
layout(location = 1) in vec2 vbo_tex_coord;
layout(location = 2) in vec4 vbo_color;

out vec2 tex_coord;
out vec4 desired_color;

uniform mat4 transform;

void main() {
    gl_Position = transform * vec4(vbo_vertex_position, 0, 1);
    tex_coord = vbo_tex_coord;
    desired_color = vbo_color;
}
`;

SHADER_TEXT_FRAG ::
`
#version 330 core

in vec2 tex_coord;
in vec4 desired_color;

uniform sampler2D atlas_texture;

out vec4 color;

void main() {
	uvec4 bytes = uvec4(texture(atlas_texture, tex_coord) * 255);
	uvec4 desired = uvec4(desired_color * 255);

	uint old_r = bytes.r;

	bytes.r = desired.r;
	bytes.g = desired.g;
	bytes.b = desired.b;
	bytes.a &= old_r & desired.a;

	color = vec4(bytes.r, bytes.g, bytes.b, bytes.a) / 255f;
}
`;