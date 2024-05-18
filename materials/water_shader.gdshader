shader_type spatial;

uniform vec3 shallow_colour : source_color;
uniform vec3 deep_colour : source_color;
uniform vec3 foam_colour: source_color;
uniform float max_depth: hint_range(0.1, 10) = 1;
uniform float absorbance: hint_range(0.0, 1.0, 0.1) = 0.7;
uniform float fresnel_amount: hint_range(0.0, 10.0, 0.1) = 5;
uniform float fresnel_strength: hint_range(0.0, 1.0, 0.1) = 0.3;
uniform float foam_depth_cutoff: hint_range(0.0, 1.0, 0.01) = 0.3;

uniform sampler2D displacement_noise;
uniform sampler2D displacement_noise_normal;
uniform vec2 wave_direction = vec2(1, 0);
uniform float wave_speed: hint_range(0, 10.0, 0.1) = 5;
uniform float wave_height: hint_range(0, 1.0, 0.01) = 0.5;

uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

float remap(float value, float current_min, float current_max, float new_min, float new_max) {
	float old_percentage = (value - current_min) / (current_max - current_min);
	return new_min + old_percentage * (new_max - new_min);
}

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

float get_noise_position(float world_position, float texture_size) {
	float noise_position = world_position / texture_size;
	noise_position -= trunc(noise_position);
	
	return noise_position;
}

void vertex() {
	vec2 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	vec2 offseted_world_position = world_position + TIME * normalize(wave_direction) * wave_speed;
	ivec2 noise_texture_size = textureSize(displacement_noise, 0);
	
	float noise_x = get_noise_position(offseted_world_position.x, float(noise_texture_size.x));
	float noise_y = get_noise_position(offseted_world_position.y, float(noise_texture_size.y));
	vec2 noise_position = vec2(noise_x, noise_y);

	float wave_multiplier = 2.0;
	float displacement = (textureLod(displacement_noise, noise_position, 0.0).r - 0.5) * 2.0 * wave_height * wave_multiplier; // 0-wave_height
	
	VERTEX.y += displacement;
	NORMAL = textureLod(displacement_noise_normal, noise_position, 0.0).xyz;
}

void fragment() {
	// Source: https://godotshaders.com/shader/another-water-shader/
	// Depth texture magic
	float depth = texture(depth_texture, SCREEN_UV, 0.0).r;
  	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float depth_texture_y = world.y / world.w;
	float vertex_y = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).y;
	float vertical_depth = vertex_y - depth_texture_y;
	
	// Changes the color of geometry behind it as the water gets deeper
	float depth_fade_distance = max_depth / 8.0;
	float depth_fade_blend = exp(-vertical_depth / depth_fade_distance);
	depth_fade_blend = clamp(depth_fade_blend, 0.0, 1.0);
	
	// Makes the water more transparent as it gets more shallow
	float alpha_blend = -vertical_depth * absorbance;
	alpha_blend = clamp(1.0 - exp(alpha_blend), 0.0, 1.0);
	
	// Mix them all together
	vec3 color_out = mix(deep_colour, shallow_colour, depth_fade_blend) + fresnel_strength * fresnel(fresnel_amount, NORMAL, VIEW);
	
	// Add foam
	if (vertical_depth < foam_depth_cutoff) {
		color_out = foam_colour;
	}
	
	ALBEDO = color_out;
	ALPHA = alpha_blend;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}