#define PIXW (1./iResolution.y)

const int MAX_STEPS = 100;
const float START_DIST = 0.001;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;



float sdSphere(vec3 p, float r)
{
    return length(p)-r;
}
vec3 getBackgroundColor(vec2 uv)
{
//uv.y [-1,1]
//y: [0,1] 
    float y=(uv.y+1.)/2.; 
    return mix(vec3(1,0,1),vec3(0,1,1),y);
}
//针对球体的法线计算
vec3 calcNormal(vec3 p) {
    vec2 e = vec2(1.0, -1.0) * 0.0005; // epsilon
    float r = 1.; // radius of sphere
    return normalize(
      e.xyy * sdSphere(p + e.xyy, r) +
      e.yyx * sdSphere(p + e.yyx, r) +
      e.yxy * sdSphere(p + e.yxy, r) +
      e.xxx * sdSphere(p + e.xxx, r));
}

float rayMarch(vec3 ro, vec3 rd,float start,float end,vec3 offset)
{
    float d=start;
    float r=1.0;
    
    for(int i=0;i<MAX_STEPS;i++)
    {
        vec3 p=ro+rd*d;

        float d1=sdSphere(p,r);
        if(d1<EPSILON)
        {
            return d;
        }
        d+=d1;
        if(d>end)
        {
            return end;
        }
    }
    return end;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
     // Normalized pixel coordinates (from -1 to 1)
     vec2 uv = (2.0*fragCoord-iResolution.xy)/iResolution.xx;

     
     float r=0.3;
     vec3 c=getBackgroundColor(uv);
     vec3 ro = vec3(0, 0, 3); // ray origin that represents camera position
     vec3 rd = normalize(vec3(uv, -1)); // ray direction
     vec3 offset=vec3(0.5,0.5,0);
     float d=rayMarch(ro,rd,START_DIST,MAX_DIST,offset);


     if(d<MAX_DIST)
     {
        //平行光源的漫反射计算
        vec3 p=ro+rd*d;
        vec3 n=calcNormal(p-offset);
        
        vec3 light_direction=normalize(vec3(2,2,7));
        vec3 light_color=vec3(1,1,1);

        float diffuse=max(0.0,dot(n,light_direction));
        c=light_color*diffuse;
     }
    // Output to screen
     fragColor = vec4(vec3(c),1.0);
}