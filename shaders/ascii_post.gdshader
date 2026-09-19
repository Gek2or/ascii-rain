shader_type canvas_item;
render_mode unshaded;

// v0.13: one stable glyph per cell, with dark negative space. No raw-3D overlay,
// random alphabet substitutions or cross-fade of two different characters.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D glyph_atlas : repeat_disable, filter_nearest;
uniform float cell_px : hint_range(1.0, 10.0, 1.0) = 6.0;
uniform float exposure : hint_range(0.75, 1.75) = 1.0;
uniform float glyph_gain : hint_range(0.5, 2.5) = 1.65;
uniform float edge_gain : hint_range(0.0, 2.0) = 0.45;
uniform float bloom_strength : hint_range(0.0, 0.7) = 0.05;
uniform float readability : hint_range(0.0, 1.0) = 0.56;
uniform float background_calm : hint_range(0.0, 1.0) = 0.28;
uniform float color_saturation : hint_range(0.35, 1.0) = 0.86;
uniform float surface_fill : hint_range(0.0, 0.70) = 0.22;
const float GLYPH_COUNT = 32.0;

float luma(vec3 c) { return dot(c, vec3(0.2126,0.7152,0.0722)); }
float palette(float tone) {
    if (tone < 0.015) { return 0.0; }
    if (tone < 0.075) { return 1.0; } // .
    if (tone < 0.15) { return 2.0; } // :
    if (tone < 0.23) { return 4.0; } // ;
    if (tone < 0.34) { return 11.0; } // +
    if (tone < 0.47) { return 14.0; } // o
    if (tone < 0.61) { return 22.0; } // *
    if (tone < 0.78) { return 30.0; } // #
    return 31.0; // @
}
void fragment() {
    vec2 cell = vec2(floor(cell_px+0.5),floor(cell_px*1.5+0.5));
    vec2 grid = SCREEN_UV / (SCREEN_PIXEL_SIZE * cell);
    vec2 local_uv = (floor(fract(grid)*cell)+0.5)/cell;
    vec2 center = (floor(grid)+0.5)*SCREEN_PIXEL_SIZE*cell;
    vec2 dx=vec2(SCREEN_PIXEL_SIZE.x*cell.x*0.28,0.0);
    vec2 dy=vec2(0.0,SCREEN_PIXEL_SIZE.y*cell.y*0.28);
    vec3 c=texture(screen_texture,center).rgb;
    vec3 l=texture(screen_texture,center-dx).rgb;
    vec3 r=texture(screen_texture,center+dx).rgb;
    vec3 u=texture(screen_texture,center-dy).rgb;
    vec3 d=texture(screen_texture,center+dy).rgb;
    vec3 avg=(c*4.0+l+r+u+d)/8.0;
    vec3 peak=max(c,max(max(l,r),max(u,d)));
    float light=smoothstep(0.48,0.86,max(peak.r,max(peak.g,peak.b)));
    // Only genuinely bright local sources get peak preservation.
    vec3 src=clamp(mix(avg,peak,0.07+0.20*light)*exposure,vec3(0.0),vec3(1.0));
    float raw=luma(src);
    float shape=smoothstep(0.045,0.30,abs(luma(l)-luma(r))+abs(luma(u)-luma(d)));
    float tone=clamp(pow(raw,mix(0.86,0.62,readability)),0.0,1.0);
    float index=palette(clamp(tone+shape*edge_gain*0.022,0.0,1.0));
    // Reserve long bars for actual edges; flat surfaces must not form scanlines.
    if (shape>0.75 && tone>0.07 && tone<0.34) {
        index=abs(luma(l)-luma(r))>abs(luma(u)-luma(d)) ? 10.0 : 5.0;
    }
    float mask=texture(glyph_atlas,vec2((index+local_uv.x)/GLYPH_COUNT,local_uv.y)).r;
    // Native-size prefiltered tiles preserve narrow strokes at 4px; tighten alpha,
    // rather than blending different glyph identities across the entire surface.
    mask=smoothstep(0.12,0.66,mask);
    vec3 hue=mix(vec3(1.0),clamp(src/max(raw,0.001),vec3(0.0),vec3(3.0)),color_saturation);
    hue/=max(luma(hue),0.001);
    float importance=max(shape,light);
    float bed_ratio=mix(0.015,0.26,clamp(surface_fill/0.70,0.0,1.0));
    float calm=background_calm*(1.0-importance);
    float stroke=clamp((0.10+tone*1.12)*glyph_gain*0.78,0.0,0.97);
    stroke*=mix(1.0,0.72,calm);
    // True black stays black; lit midtones get sharp ink, not a grey blanket.
    stroke*=smoothstep(0.002,0.024,raw);
    vec3 bed=hue*tone*bed_ratio;
    vec3 ink=clamp(hue*stroke,vec3(0.0),vec3(0.98));
    vec3 color=mix(bed,ink,mask);
    color+=max(avg-vec3(0.84),vec3(0.0))*bloom_strength*0.10;
    COLOR=vec4(clamp(color,vec3(0.0),vec3(1.0)),1.0);
}
