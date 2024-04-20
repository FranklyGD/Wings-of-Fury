local shaders = {}

shaders.color_mat = love.graphics.newShader([[
	extern vec3 matrix[4];

	vec4 effect(vec4 color, Image tex, vec2 texCoords, vec2 screenCoords) {
		vec4 pixel = Texel(tex, texCoords);

		float r = pixel.r * matrix[0].r + pixel.g * matrix[1].r + pixel.b * matrix[2].r + matrix[3].r;
		float g = pixel.r * matrix[0].g + pixel.g * matrix[1].g + pixel.b * matrix[2].g + matrix[3].g;
		float b = pixel.r * matrix[0].b + pixel.g * matrix[1].b + pixel.b * matrix[2].b + matrix[3].b;

		return vec4(r, g, b, pixel.a);
	}
]])

return shaders