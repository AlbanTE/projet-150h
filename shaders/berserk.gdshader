shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color : source_color = vec4(0.5, 0.0, 1.0, 0.5); 

void fragment() {
    vec2 uv = SCREEN_UV;
    float d = distance(uv, vec2(0.5, 0.5));
    float vignette = smoothstep(0.4, 1.0, d);
    COLOR = vec4(color.rgb, vignette * intensity * color.a);
}
