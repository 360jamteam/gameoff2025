shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

	// Wind Waker style water - NekotoArts
	// https://godotshaders.com/shader/wind-waker-water-no-textures-needed/
	// Adapted from https://www.shadertoy.com/view/3tKBDz
	// After which I added in some fractal Brownian motion
	// as well as vertex displacement

	uniform vec4 WATER_COL =  vec4(0.04, 0.38, 0.88, 1.0);
	uniform vec4 WATER2_COL =  vec4(0.04, 0.35, 0.78, 1.0);
	uniform vec4 FOAM_COL = vec4(0.8125, 0.9609, 0.9648, 1.0);
	uniform float distortion_speed = 2.0;
	uniform vec2 tile = vec2(50.0, 50.0);
	uniform float height = 2.0;
	uniform vec2 wave_size = vec2(2.0, 2.0);
	uniform float wave_speed = 1.5;

	const float M_2PI = 6.283185307;
	const float M_6PI = 18.84955592;

	// ---- Nicole's spawned waves (synced with water.gd) ----
	const int MAX_SPAWNED_WAVES = 32;

	uniform int spawned_wave_count;
	uniform vec2 spawned_wave_centers[MAX_SPAWNED_WAVES];
	uniform float spawned_wave_times[MAX_SPAWNED_WAVES];
	uniform float spawned_wave_radius;
	uniform float spawned_wave_height;
	uniform float spawned_wave_lifetime;
	// -------------------------------------------------------


	float random(vec2 uv) {
	    return fract(sin(dot(uv.xy,
	        vec2(12.9898,78.233))) *
	            43758.5453123);
	}

void fragment()
{
	vec2 uv = UV;

    ALBEDO = vec3(water(uv * tile, vec3(0,1,0), TIME * distortion_speed));
}
