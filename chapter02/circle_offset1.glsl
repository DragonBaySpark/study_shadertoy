#define PIXW (1./iResolution.y)

vec3 sdfCircle(vec2 uv, float r,vec2 offset)
{
     uv=uv-offset;
     float d=length(uv)-r;
     return d>0.?vec3(0.):vec3(1.);
}
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
     // Normalized pixel coordinates (from -1 to 1)
     vec2 uv = (2.0*fragCoord-iResolution.xy)/min(iResolution.x,iResolution.y);

     float r=0.3;
     vec3 c=sdfCircle(uv,r,vec2(0.3,0.3));
    // Output to screen
     fragColor = vec4(vec3(c),1.0);
}