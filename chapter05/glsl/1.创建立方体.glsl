#define PIXW (1./iResolution.y)

const int MAX_STEPS = 100;
const float START_DIST = 0.001;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;

struct SDFResult
{
    float d;
    vec3 color;
};

vec3 getBackgroundColor(vec2 uv)
{
//uv.y [-1,1]
//y: [0,1] 
    float y=(uv.y+1.)/2.; 
    return mix(vec3(1,0,1),vec3(0,1,1),y);
}

SDFResult sdSphere(vec3 p, float r,vec3 offset,vec3 color)
{
    return SDFResult(length(p-offset)-r,color);
}
SDFResult sdBox( vec3 p, vec3 b,vec3 offset,vec3 color )
{
  vec3 q = abs(p-offset) - b;
  return SDFResult(length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0),color);
}

SDFResult minWithColor(SDFResult a,SDFResult b)
{
    if (a.d<b.d)
    {
        return a;
    }
    return b;
}
SDFResult sdScene(vec3 p)
{
    
    SDFResult result1=sdSphere(p,1.0,vec3(-2.5,0.5,-2),vec3(0.,0.8,0.8));
    SDFResult result2=sdSphere(p,1.0,vec3(2.5,0.5,-2),vec3(1.,0.58,0.29));
    
    //SDFResult result=minWithColor(result1,result2);
    SDFResult result=sdBox(p,vec3(1.0,1.0,.5),vec3(0.2,0.2,0.2),vec3(1.,0.,0.));
    return result;
}
//法线计算
vec3 calcNormal(vec3 p) {
    vec2 e = vec2(1.0, -1.0) * 0.0005; // epsilon
    float r = 1.; // radius of sphere
    return normalize(
      e.xyy * sdScene(p + e.xyy).d +
      e.yyx * sdScene(p + e.yyx).d +
      e.yxy * sdScene(p + e.yxy).d +
      e.xxx * sdScene(p + e.xxx).d);
}

SDFResult rayMarch(vec3 ro, vec3 rd,float start,float end)
{
    float d=start;
    float r=1.0;
    SDFResult result;
    for(int i=0;i<MAX_STEPS;i++)
    {
        vec3 p=ro+rd*d;

        result=sdScene(p);
        d+=result.d;
        if(result.d<EPSILON || d>end) break;
        
    }
    result.d=d;
    return result;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
     // Normalized pixel coordinates (from -1 to 1)
     vec2 uv = (2.0*fragCoord-iResolution.xy)/iResolution.xx;

     
     float r=0.3;

     vec3 backgroundColor = vec3(0.835, 1, 1);
     //vec3 c=getBackgroundColor(uv);
     vec3 c=backgroundColor;
     vec3 ro = vec3(0, 0, 3); // ray origin that represents camera position
     vec3 rd = normalize(vec3(uv, -1)); // ray direction
     
     SDFResult result=rayMarch(ro,rd,START_DIST,MAX_DIST);
     

     float d=result.d;

     if(d<MAX_DIST)
     {
        //平行光源的漫反射计算
        vec3 p=ro+rd*d;
        vec3 n=calcNormal(p);
        
        vec3 lightPosition=vec3(2,2,7);
        //vec3 light_direction=normalize(vec3(1,0,5));
        vec3 light_direction=normalize(lightPosition-p);
        vec3 light_color=vec3(1,1,1);

        float diffuse=max(0.0,dot(n,light_direction));
        diffuse=clamp(diffuse,0.1,1.0);
        c=light_color*diffuse*result.color+backgroundColor*0.2;
        
     }
    // Output to screen
     fragColor = vec4(vec3(c),1.0);
}