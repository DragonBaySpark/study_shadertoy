#define PIXW (1./iResolution.y)

vec3 getBackgroundColor(vec2 uv)
{
//uv.y [-1,1]
//y: [0,1] 
    float y=(uv.y+1.)/2.; 
    return mix(vec3(1,0,1),vec3(0,1,1),y);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
     // Normalized pixel coordinates (from -1 to 1)
     vec2 uv = (2.0*fragCoord-iResolution.xy)/iResolution.xx;

     float r=0.3;
     vec3 c=getBackgroundColor(uv);
    // Output to screen
     fragColor = vec4(vec3(c),1.0);
}