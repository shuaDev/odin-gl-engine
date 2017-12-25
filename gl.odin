/*
 *  @Name:     gl
 *
 *  @Author:   Joshua Manton
 *  @Email:    joshuamarkk@gmail.com
 *  @Creation: 21-12-2017 07:19:30 UTC-8
 *
 *  @Last By:   Joshua Manton
 *  @Last Time: 24-12-2017 16:36:53 UTC-8
 *
 *  @Description:
 *
 */

import "core:fmt.odin"

export "shared:odin-gl/gl.odin"

Shader_Program :: u32;
VAO :: u32;
VBO :: u32;
Texture :: u32;

gen_vao :: inline proc() -> VAO {
	vao: u32;
	GenVertexArrays(1, &vao);
	return cast(VAO)vao;
}

bind_vao :: inline proc(vao: VAO) {
	BindVertexArray(cast(u32)vao);
}

delete_vao :: inline proc(vao: VAO) {
	DeleteVertexArrays(1, cast(^u32)&vao);
}

gen_buffer :: inline proc() -> VBO {
	vbo: u32;
	GenBuffers(1, &vbo);
	return cast(VBO)vbo;
}

bind_buffer :: inline proc(vbo: VBO) {
	BindBuffer(ARRAY_BUFFER, cast(u32)vbo);
}

load_shader_files :: inline proc(vs, fs: string) -> (Shader_Program, bool) {
	program, ok := load_shaders(vs, fs);
	return cast(Shader_Program)program, ok;
}

use_program :: inline proc(program: Shader_Program) {
	UseProgram(cast(u32)program);
}

gen_texture :: inline proc() -> Texture {
	texture: u32;
	GenTextures(1, &texture);
	return cast(Texture)texture;
}

bind_texture1d :: inline proc(texture: Texture) {
	BindTexture(TEXTURE_1D, cast(u32)texture);
}

bind_texture2d :: inline proc(texture: Texture) {
	BindTexture(TEXTURE_2D, cast(u32)texture);
}

// ActiveTexture() is guaranteed to go from 0-47 on all implementations of OpenGL, but can go higher on some
active_texture0 :: inline proc() {
	ActiveTexture(TEXTURE0);
}

active_texture1 :: inline proc() {
	ActiveTexture(TEXTURE1);
}

active_texture2 :: inline proc() {
	ActiveTexture(TEXTURE2);
}

active_texture3 :: inline proc() {
	ActiveTexture(TEXTURE3);
}

active_texture4 :: inline proc() {
	ActiveTexture(TEXTURE4);
}

c_string_buffer: [4096]byte;
c_string :: proc(fmt_: string, args: ...any) -> ^byte {
    s := fmt.bprintf(c_string_buffer[..], fmt_, ...args);
    c_string_buffer[len(s)] = 0;
    return cast(^byte)&c_string_buffer[0];
}

get_uniform_location :: inline proc(program: Shader_Program, str: string) -> i32 {
	c_str := c_string(str);
	return GetUniformLocation(cast(u32)program, c_str);
}

uniform :: proc[uniform1f,
				uniform2f,
				uniform3f,
				uniform4f,
				uniform1i,
				uniform2i,
				uniform3i,
				uniform4i,
				];

uniform1f :: inline proc(program: Shader_Program, name: string, v0: f32) {
	location := get_uniform_location(program, name);
	Uniform1f(location, v0);
}

uniform2f :: inline proc(program: Shader_Program, name: string, v0: f32, v1: f32) {
	location := get_uniform_location(program, name);
	Uniform2f(location, v0, v1);
}

uniform3f :: inline proc(program: Shader_Program, name: string, v0: f32, v1: f32, v2: f32) {
	location := get_uniform_location(program, name);
	Uniform3f(location, v0, v1, v2);
}

uniform4f :: inline proc(program: Shader_Program, name: string, v0: f32, v1: f32, v2: f32, v3: f32) {
	location := get_uniform_location(program, name);
	Uniform4f(location, v0, v1, v2, v3);
}

uniform1i :: inline proc(program: Shader_Program, name: string, v0: i32) {
	location := get_uniform_location(program, name);
	Uniform1i(location, v0);
}

uniform2i :: inline proc(program: Shader_Program, name: string, v0: i32, v1: i32) {
	location := get_uniform_location(program, name);
	Uniform2i(location, v0, v1);
}

uniform3i :: inline proc(program: Shader_Program, name: string, v0: i32, v1: i32, v2: i32) {
	location := get_uniform_location(program, name);
	Uniform3i(location, v0, v1, v2);
}

uniform4i :: inline proc(program: Shader_Program, name: string, v0: i32, v1: i32, v2: i32, v3: i32) {
	location := get_uniform_location(program, name);
	Uniform4i(location, v0, v1, v2, v3);
}

uniform1fv :: inline proc(program: Shader_Program, name: string, count: i32, value: ^f32) {
	location := get_uniform_location(program, name);
	Uniform1fv(location, count, value);
}

uniform2fv :: inline proc(program: Shader_Program, name: string, count: i32, value: ^f32) {
	location := get_uniform_location(program, name);
	Uniform2fv(location, count, value);
}

uniform3fv :: inline proc(program: Shader_Program, name: string, count: i32, value: ^f32) {
	location := get_uniform_location(program, name);
	Uniform3fv(location, count, value);
}

uniform4fv :: inline proc(program: Shader_Program, name: string, count: i32, value: ^f32) {
	location := get_uniform_location(program, name);
	Uniform4fv(location, count, value);
}

uniform1iv :: inline proc(program: Shader_Program, name: string, count: i32, value: ^i32) {
	location := get_uniform_location(program, name);
	Uniform1iv(location, count, value);
}

uniform2iv :: inline proc(program: Shader_Program, name: string, count: i32, value: ^i32) {
	location := get_uniform_location(program, name);
	Uniform2iv(location, count, value);
}

uniform3iv :: inline proc(program: Shader_Program, name: string, count: i32, value: ^i32) {
	location := get_uniform_location(program, name);
	Uniform3iv(location, count, value);
}

uniform4iv :: inline proc(program: Shader_Program, name: string, count: i32, value: ^i32) {
	location := get_uniform_location(program, name);
	Uniform4iv(location, count, value);
}

uniform_matrix2fv :: inline proc(program: Shader_Program, name: string, count: i32, transpose: bool, value: ^f32) {
	location := get_uniform_location(program, name);
	UniformMatrix2fv(location, count, transpose ? 1 : 0, value);
}

uniform_matrix3fv :: inline proc(program: Shader_Program, name: string, count: i32, transpose: bool, value: ^f32) {
	location := get_uniform_location(program, name);
	UniformMatrix3fv(location, count, transpose ? 1 : 0, value);
}

uniform_matrix4fv :: inline proc(program: Shader_Program, name: string, count: i32, transpose: bool, value: ^f32) {
	location := get_uniform_location(program, name);
	UniformMatrix4fv(location, count, transpose ? 1 : 0, value);
}

