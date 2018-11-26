package collision

using import "core:fmt"
using import "core:math"

import "core:sort"

main :: proc() {

}

//
// Collision Scene API
//

Box :: struct {
	size: Vec3,
}

Collider :: struct {
	position: Vec3,
	box: Box,

}

Collision_Scene :: struct {
	colliders: map[i32]Collider,
}

add_collider_to_scene :: proc(using scene: ^Collision_Scene, collider: Collider, auto_cast handle: i32) {
	_, ok := colliders[handle];
	assert(!ok);
	colliders[handle] = collider;
}

get_collider :: proc(using scene: ^Collision_Scene, auto_cast handle: i32) -> (Collider, bool) {
	assert(handle != 0);

	coll, ok := colliders[handle];
	return coll, ok;
}

update_collider :: proc(using scene: ^Collision_Scene, auto_cast handle: i32, collider: Collider) {
	assert(handle != 0);

	_, ok := colliders[handle];
	assert(ok);

	colliders[handle] = collider;
}

remove_collider :: proc(using scene: ^Collision_Scene, auto_cast handle: i32) {
	assert(handle != 0);
	delete_key(&colliders, handle);
}

destroy_collision_scene :: proc(using scene: ^Collision_Scene) {
	delete(colliders);
}

// todo(josh): these *cast functions should probably sort their outputs
linecast :: proc(using scene: ^Collision_Scene, origin: Vec3, velocity: Vec3, out_hits: ^[dynamic]Hit_Info) {
	clear(out_hits);
	for handle, collider in colliders {
		info, ok := cast_line_box(origin, velocity, collider.position, collider.box.size, handle);
		if ok do append(out_hits, info);
	}
	sort.quick_sort_proc(out_hits[:], proc(a, b: Hit_Info) -> int {
		if a.fraction0 < b.fraction0 do return -1;
		return 1;
	});
}

// todo(josh): test this, not sure if it works
boxcast :: proc(using scene: ^Collision_Scene, origin, size, velocity: Vec3, other_position, other_size: Vec3, out_hits: ^[dynamic]Hit_Info) {
	clear(out_hits);
	for handle, collider in colliders {
		info, ok := cast_box_box(origin, size, velocity, collider.position, collider.box.size, handle);
		if ok do append(out_hits, info);
	}
	sort.quick_sort_proc(out_hits[:], proc(a, b: Hit_Info) -> int {
		if a.fraction0 < b.fraction0 do return -1;
		return 1;
	});
}

//
// raw stuff
//

sqr_magnitude :: inline proc(a: Vec3) -> f32 do return dot(a, a);

closest_point_on_line :: proc(origin: Vec3, p1, p2: Vec3) -> Vec3 {
	direction := p2 - p1;
	square_length := sqr_magnitude(direction);
	if (square_length == 0.0) {
		// p1 == p2
		dir_from_point := p1 - origin;
		return p1;
	}

	dot := dot(origin - p1, p2 - p1) / square_length;
	t := max(min(dot, 1), 0);
	projection := p1 + t * (p2 - p1);
	return projection;
}

Hit_Info :: struct {
	handle: i32, // users data to identify this collider as an entity in their code or something like that

	// Fraction (0..1) of the distance that the ray started intersecting
	fraction0: f32,
	// Fraction (0..1) of the distance that the ray stopped intersecting
	fraction1: f32,

	// Point that the ray started intersecting
	point0: Vec3,
	// Point that the ray stopped intersecting
	point1: Vec3,

	// todo(josh)
	// normal0: Vec3,
	// normal1: Vec3,
}

cast_box_box :: proc(b1pos, b1size: Vec3, box_direction: Vec3, b2pos, b2size: Vec3, b2_handle : i32 = 0) -> (Hit_Info, bool) {
	b2size += b1size;
	return cast_line_box(b1pos, box_direction, b2pos, b2size, b2_handle);
}

cast_line_box :: proc(line_origin, line_velocity: Vec3, boxpos, boxsize: Vec3, box_handle : i32 = 0) -> (Hit_Info, bool) {
	inverse := Vec3{
		1/line_velocity.x,
		1/line_velocity.y,
		1/line_velocity.z,
	};

	lb := boxpos - boxsize * 0.5;
	rt := boxpos + boxsize * 0.5;

	t1 := (lb.x - line_origin.x)*inverse.x;
	t2 := (rt.x - line_origin.x)*inverse.x;
	t3 := (lb.y - line_origin.y)*inverse.y;
	t4 := (rt.y - line_origin.y)*inverse.y;
	t5 := (lb.z - line_origin.z)*inverse.z;
	t6 := (rt.z - line_origin.z)*inverse.z;

	tmin := max(max(min(t1, t2), min(t3, t4)), min(t5, t6));
	tmax := min(min(max(t1, t2), max(t3, t4)), max(t5, t6));

	// if tmax < 0, ray (line) is intersecting AABB, but the whole AABB is behind us
	if tmax < 0 do return {}, false;

	// if tmin > tmax, ray doesn't intersect AABB
	if tmin > tmax do return {}, false;

	info := Hit_Info{box_handle, tmin, tmax, line_origin + (line_velocity * tmin), line_origin + (line_velocity * tmax)};
	return info, true;
}

@(deprecated="Not yet implemented")
cast_box_circle :: proc(box_min, box_max: Vec3, box_direction: Vec3, circle_position: Vec3, circle_radius: f32) -> (Hit_Info, bool) {
	// todo(josh): this sounds like a nightmare
	assert(false);
	return Hit_Info{}, false;
}

// todo(josh): test this, not sure if it works
cast_line_circle :: proc(line_origin, line_velocity: Vec3, circle_center: Vec3, circle_radius: f32, circle_handle : i32 = 0) -> (Hit_Info, bool) {
	direction := line_origin - circle_center;
	a := dot(line_velocity, line_velocity);
	b := dot(direction, line_velocity);
	c := dot(direction, direction) - circle_radius * circle_radius;

	disc := b * b - a * c;
	if (disc < 0) {
		return Hit_Info{}, false;
	}

	sqrt_disc := sqrt(disc);
	invA: f32 = 1.0 / a;

	tmin := (-b - sqrt_disc) * invA;
	tmax := (-b + sqrt_disc) * invA;
	tmax = min(tmax, 1);

	inv_radius: f32 = 1.0 / circle_radius;

	pmin := line_origin + tmin * line_velocity;
	// normal := (pmin - circle_center) * inv_radius;

	pmax := line_origin + tmax * line_velocity;
	// normal[i] = (point[i] - circle_center) * invRadius;

	info := Hit_Info{circle_handle, tmin, tmax, pmin, pmax};

	return info, true;
}

overlap_point_box :: inline proc(origin: Vec3, box_min, box_max: Vec3) -> bool {
	return origin.x < box_max.x
		&& origin.x > box_min.x
		&& origin.y < box_max.y
		&& origin.y > box_min.y
		&& origin.z < box_max.z
		&& origin.z > box_min.z;
}

overlap_point_circle :: inline proc(origin: Vec3, circle_position: Vec3, circle_radius: f32) -> bool {
	return sqr_magnitude(origin - circle_position) < (circle_radius * circle_radius);
}




// todo(josh): the rest of these

// cast_circle_box :: proc(circle_origin, circle_direction: Vec3, circle_radius: f32, boxpos, boxsize: Vec3) -> (Hit_Info, bool) {
// 	compare_hits :: proc(source: ^Hit_Info, other: Hit_Info) {
// 		if other.fraction0 < source.fraction0 {
// 			source.fraction0 = other.fraction0;
// 			source.point0    = other.point0;
// 		}

// 		if other.fraction1 > source.fraction1 {
// 			source.fraction1 = other.fraction1;
// 			source.point1    = other.point1;
// 		}
// 	}

// 	tl := Vec3{box_min.x, box_max.y};
// 	tr := Vec3{box_max.x, box_max.y};
// 	br := Vec3{box_max.x, box_min.y};
// 	bl := Vec3{box_min.x, box_min.y};

// 	// Init with fraction fields at extremes for comparisons
// 	final_hit_info: Hit_Info;
// 	final_hit_info.fraction0 = 1;
// 	final_hit_info.fraction1 = 0;

// 	did_hit := false;

// 	// Corner circle checks
// 	{
// 		circle_positions := [4]Vec3{tl, tr, br, bl};
// 		for pos in circle_positions {
// 			info, hit := cast_line_circle(circle_origin, circle_direction, pos, circle_radius);
// 			if hit {
// 				did_hit = true;
// 				compare_hits(&final_hit_info, info);
// 			}
// 		}
// 	}

// 	// Center box checks
// 	{
// 		// box0 is tall box, box1 is wide box
// 		box0_min := box_min - Vec3{0, circle_radius};
// 		box0_max := box_max + Vec3{0, circle_radius};

// 		box1_min := box_min - Vec3{circle_radius, 0};
// 		box1_max := box_max + Vec3{circle_radius, 0};

// 		info0, hit0 := cast_line_box(circle_origin, circle_direction, box0_min, box0_max);
// 		if hit0 {
// 			did_hit = true;
// 			compare_hits(&final_hit_info, info0);
// 		}

// 		info1, hit1 := cast_line_box(circle_origin, circle_direction, box1_min, box1_max);
// 		if hit1 {
// 			did_hit = true;
// 			compare_hits(&final_hit_info, info1);
// 		}
// 	}

// 	return final_hit_info, did_hit;
// }
