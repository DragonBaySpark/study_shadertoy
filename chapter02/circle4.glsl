#define PIXW (1./iResolution.y)
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
     // Normalized pixel coordinates (from -1 to 1)
     vec2 uv = (2.0*fragCoord-iResolution.xy)/iResolution.xx;

     float r=0.3;
     float c=smoothstep(0.,0.+30.*PIXW,length(uv)-r);
    // Output to screen
     fragColor = vec4(vec3(c),1.0);
}