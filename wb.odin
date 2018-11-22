package workbench

using import        "core:math"
using import        "core:fmt"
      import        "core:sort"
      import        "core:strings"
      import        "core:mem"
      import        "core:os"
      import        "core:sys/win32"

      import odingl "external/gl"
      import imgui  "external/imgui"

      import stb    "external/stb"
      import        "external/glfw"

DEVELOPER :: true;

//
// Game loop stuff
//

client_target_framerate:  f32;
fixed_delta_time: f32;

whole_frame_time_ra: Rolling_Average(f64, 100);

do_log_frame_boundaries := false;

// _on_before_client_update := make_event(f32);
// _on_after_client_update  := make_event(f32);
f: f32;
make_simple_window :: proc(window_name: string,
                           window_width, window_height: int,
                           opengl_version_major, opengl_version_minor: int,
                           _target_framerate: f32,
                           stage: Stage,
                           camera: ^Camera) {

	current_camera = camera;

	client_target_framerate = _target_framerate;

	_init_glfw(window_name, window_width, window_height, opengl_version_major, opengl_version_minor);
	_init_opengl(opengl_version_major, opengl_version_minor);
	_init_random_number_generator();
	_init_dear_imgui();

	acc: f32;
	fixed_delta_time = cast(f32)1 / client_target_framerate;

	start_stage(stage);

	game_loop:
	for !glfw.WindowShouldClose(main_window) && !wb_should_close {
		frame_start := glfw.GetTime();
		defer {
			frame_end := glfw.GetTime();
			rolling_average_push_sample(&whole_frame_time_ra, frame_end - frame_start);
		}

		last_time := time;
		time = cast(f32)glfw.GetTime();
		lossy_delta_time = time - last_time;
		acc += lossy_delta_time;

		if acc >= fixed_delta_time {
			for {
				if do_log_frame_boundaries {
					logln("[WB] FRAME #", frame_count);
				}

				frame_count += 1;

				imgui_begin_new_frame();
	    		imgui.push_font(imgui_font_default);

				_update_catalog();
				_update_renderer();
				_update_glfw();
				_update_input();
				_update_tween();
				_update_ui();
				_update_debug_window();

				_update_stages(); // calls client updates

				_late_update_ui();

				// call_coroutines();
	    		imgui.pop_font();

				acc -= fixed_delta_time;
				if acc >= fixed_delta_time {
					imgui_render(false);
				}
				else {
					break;
				}
			}
		}


		_render_stages();
		imgui_render(true);

		frame_end := win32.time_get_time();
		glfw.SwapBuffers(main_window);

		odingl.Finish(); // <- what?

		log_gl_errors("after SwapBuffers()");
	}
}

wb_should_close: bool;
exit :: inline proc() {
	wb_should_close = true;
}

Stage :: struct {
	name: string,

	init: proc(),
	update: proc(f32),
	render: proc(f32),
	end: proc(),
}

_Stage_Internal :: struct {
	using stage: Stage,

	id: Stage_ID,
}

Stage_ID :: distinct int;
cur_stage_serial: int;
all_stages: map[Stage_ID]_Stage_Internal;
new_stages: [dynamic]_Stage_Internal;
end_stages: [dynamic]Stage_ID;

start_stage :: proc(stage: Stage) -> Stage_ID {
	id := cast(Stage_ID)cur_stage_serial;
	cur_stage_serial += 1;

	stage_internal := _Stage_Internal{stage, id};
	append(&new_stages, stage_internal);
	return id;
}

end_stage :: proc(id: Stage_ID) {
	append(&end_stages, id);
}

_update_stages :: proc() {
	// Flush new stages
	{
		for stage in new_stages {
			if stage.init != nil {
				stage.init();
			}
			all_stages[stage.id] = stage;
		}
		clear(&new_stages);
	}

	// Update stages
	{
		for id, stage in all_stages {
			if stage.update != nil {
				stage.update(fixed_delta_time);
			}
		}
	}

	// Remove ended stages
	{
		for id in end_stages {
			delete_key(&all_stages, id);
		}
		clear(&new_stages);
	}
}

_render_stages :: proc() {
	// Update stages
	{
		for id, stage in all_stages {
			render_stage(stage);
		}
	}
}

WB_Debug_Data :: struct {
	camera_position: Vec3,
	camera_rotation_euler: Vec3,
	camera_rotation_quat: Quat,
	precise_lossy_delta_time_ms: f64,
	fixed_delta_time: f32,
	client_target_framerate: f32,
	draw_calls: i32,
}

debug_window_open: bool;
last_saved_dt: f32;

_update_debug_window :: proc() {
	if get_input_down(Input.F1) {
		debug_window_open = !debug_window_open;
	}

	if debug_window_open {
		data := WB_Debug_Data{
			current_camera.position,
			current_camera.rotation,
			degrees_to_quaternion(current_camera.rotation),
			rolling_average_get_value(&whole_frame_time_ra) * 1000,
			fixed_delta_time,
			client_target_framerate,
			num_draw_calls,

		};
		if imgui.begin("Debug") {
			defer imgui.end();

			imgui_struct(&data, "wb_debug_data");
			imgui.checkbox("Debug Rendering", &debugging_rendering);
			imgui.checkbox("Debug UI", &debugging_ui);
			imgui.checkbox("Log Frame Boundaries", &do_log_frame_boundaries);
			imgui.im_slider_int("max_draw_calls", &debugging_rendering_max_draw_calls, -1, num_draw_calls, nil);
		}
	}
}

// Coroutine :: struct {
// 	callback: proc(rawptr, int),
// 	userdata: rawptr,

// 	state: int,
// }

// coroutines: [dynamic]Coroutine;

// start_coroutine :: proc(callback: proc(rawptr, int), userdata: rawptr, loc := #caller_location) -> bool {
// 	if callback == nil {
// 		logln("Nil callback passed to start_coroutine() from: ", loc);
// 		return false;
// 	}

// 	coroutine := Coroutine{callback, userdata, 0};
// 	append(&coroutines, coroutine);
// 	return true;
// }

// call_coroutines :: proc() {
// 	for _, i in coroutines {
// 		coroutine := &coroutines[i];
// 		assert(coroutine.callback != nil);

// 		continue_calling := coroutine.callback(coroutine.userdata, coroutine.state);
// 	}
// }

main :: proc() {
	when DEVELOPER {
		_test_csv();
		_test_alphabetical_notation();
	}
}