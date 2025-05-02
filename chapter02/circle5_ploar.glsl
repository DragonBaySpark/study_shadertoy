#define PIXW (1./iResolution.y)
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv=(fragCoord.xy-.5*iResolution.xy)*PIXW;
    
    vec4 O=vec4(smoothstep(0.+10.*PIXW,0.,length(uv)-0.5));
    
    uv=vec2(length(uv),atan(-uv.y,-uv.x));//polar system
    fragColor=mix(vec4(0),O,uv.y/6.28+.5);

}