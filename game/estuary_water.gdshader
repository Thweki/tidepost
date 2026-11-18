shader_type canvas_item;
render_mode unshaded;
uniform vec4 deep_water : source_color = vec4(.15,.36,.43,1.);
uniform vec4 shoal : source_color = vec4(.27,.54,.53,1.);
uniform vec4 sunlit : source_color = vec4(.98,.81,.57,1.);
uniform float seconds;
uniform float distance_px;
uniform float sun_x;

float hash(vec2 point){
	return fract(sin(dot(point,vec2(127.1,311.7)))*43758.5453);
}

float field(vec2 point){
	vec2 cell=floor(point),part=fract(point);
	part=part*part*(3.0-2.0*part);
	return mix(mix(hash(cell),hash(cell+vec2(1,0)),part.x),
		mix(hash(cell+vec2(0,1)),hash(cell+vec2(1,1)),part.x),part.y);
}

void fragment(){
	vec2 pixel=floor(UV*vec2(480.,250.));
	vec2 world=pixel+vec2(distance_px,0.);
	float tide=field(world*vec2(.021,.049)+vec2(seconds*.12,0.));
	float wave=field(world*vec2(.088,.64)+vec2(seconds*.32,-seconds*.24));
	float ridge=abs(sin(pixel.y*1.2+tide*5.6+seconds*1.7));
	float shade=floor(clamp(tide*.78+wave*.35,0.,1.)*7.)/7.;
	vec3 color=mix(deep_water.rgb,shoal.rgb,shade);
	float ribbon=abs(pixel.x-sun_x-sin(pixel.y*.15+seconds*.35)*8.);
	float shine=1.-smoothstep(5.,42.+pixel.y*.13,ribbon);
	float crest=smoothstep(.46,.82,wave)*step(.86,ridge);
	color=mix(color,sunlit.rgb,shine*(.08+crest*.80));
	color+=vec3(.12,.17,.15)*step(.83,wave)*step(.4,ridge);
	COLOR=vec4(color,1.);
}
