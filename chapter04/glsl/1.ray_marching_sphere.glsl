#define PIXW (1./iResolution.y)

const int MAX_STEPS = 100;
const float START_DIST = 0.001;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;


float sdfCircle(vec3 p, float r,vec3 offset)
{
    return length(p-offset)-r;
}

vec3 getBackgroundColor(vec2 uv)
{
//uv.y [-1,1]
//y: [0,1] 
    float y=(uv.y+1.)/2.; 
    return mix(vec3(1,0,1),vec3(0,1,1),y);
}

float rayMarch(vec3 ro, vec3 rd,float start,float end)
{
    float d=start;
    float r=1.0;
    vec3 offset=vec3(0.5,0.5,0);
    for(int i=0;i<MAX_STEPS;i++)
    {
        vec3 p=ro+rd*d;

        float d1=sdfCircle(p,r,offset);
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
     float d=rayMarch(vec3(0,0,5),vec3(uv,-1),START_DIST,MAX_DIST);
     if(d<MAX_DIST)
     {
        c=vec3(1,0,0);
     }
    // Output to screen
     fragColor = vec4(vec3(c),1.0);
}