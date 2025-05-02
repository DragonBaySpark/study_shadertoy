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
mat4 rotationX(float theta)
{
    return mat4(
        1.0, 0.0, 0.0, 0.0,
        0.0, cos(theta), -sin(theta), 0.0,
        0.0, sin(theta), cos(theta), 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

mat4 rotationY(float theta)
{
    return mat4(
        cos(theta), 0.0, sin(theta), 0.0,
        0.0, 1.0, 0.0, 0.0,
        -sin(theta), 0.0, cos(theta), 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}
mat4 rotationZ(float theta)
{
    return mat4(
        cos(theta), -sin(theta), 0.0, 0.0,
        sin(theta), cos(theta), 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

SDFResult sdBox( vec3 p, vec3 b,vec3 offset,vec3 color )
{
  vec3 q = abs(p-offset) - b;
  return SDFResult(length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0),color);
}

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
SDFResult sdFloor(vec3 p,vec3 color)
{
    float d=p.y+1.;
    return SDFResult(d,color);
}

SDFResult minWithColor(SDFResult a,SDFResult b)
{
    if (a.d<b.d)
    {
        return a;
    }
    return b;
}

mat3 camera(vec3 cameraPos, vec3 lookAtPoint, vec3 upVector) {
    vec3 cd = normalize(lookAtPoint - cameraPos); // camera direction
    vec3 cr = normalize(cross(upVector, cd)); // camera right
    vec3 cu = normalize(cross(cd, cr)); // camera up

    return mat3(-cr, cu, -cd); //转换为x轴向右，y轴向上，z轴向屏幕外边的右手坐标系
}

SDFResult sdScene(vec3 p)
{
    
    SDFResult result1=sdSphere(p,1.,vec3(0,0.2,-0.5),vec3(0.7,0.5,0.));
    //SDFResult result2=sdBox(p,vec3(1.,1.0,1.),vec3(0,0.2,-4),vec3(0.,1.,0.));
    //SDFResult result3=sdBox(p,vec3(1.,1.0,1.),vec3(4,0.2,-4),vec3(0.,0.,1.));
    
    SDFResult result=result1;//minWithColor(result1,result2);
    //result=minWithColor(result,result3);

     vec3 floorColor = vec3(1. + 0.7*mod(floor(p.x) + floor(p.z), 2.0));
    //result=minWithColor(result, sdFloor(p,floorColor));
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
     vec3 lp=vec3(0,0.2,-4);
     vec3 ro = vec3(0, 0, 3); // ray origin that represents camera position
     //float theta=iTime*0.5;
     //float cameraRadius=10.;
     //ro.x=cameraRadius*cos(theta)+lp.x;
     //ro.z=cameraRadius*sin(theta)+lp.z;
     vec3 rd = camera(ro,lp,vec3(0,1,0))*normalize(vec3(uv, -1)); // ray direction
     
     SDFResult result=rayMarch(ro,rd,START_DIST,MAX_DIST);
     

     float d=result.d;

     if(d<MAX_DIST)
     {
        //平行光源的漫反射计算
        vec3 p=ro+rd*d;
        vec3 n=calcNormal(p);
        
        vec3 lightPosition=vec3(2,2,7);
        //vec3 lightPosition=vec3(-8,-6,-5);
        //vec3 light_direction=normalize(vec3(1,0,5));
        vec3 light_direction=normalize(lightPosition-p);
        vec3 light_color=vec3(1,1,1);


        //ambient
        float k_a=0.6;
        vec3 i_a=vec3(0.7,0.7,0);
        vec3 ambient=i_a*k_a;


        //diffuse
        float diffuse=clamp(dot(n,light_direction),0.0,1.0);
        diffuse=clamp(diffuse,0.1,1.0);

        vec3 i_d=vec3(0.7,0.5,0.);
        float k_d=0.5;
        vec3 diffuse_color=k_d*diffuse*i_d;


        //specular
        float k_s=0.6;
        float dotRV=dot(n,reflect(-light_direction,n));
        dotRV=clamp(dotRV,0.0,1.0); 
        vec3 i_s=vec3(1,1,1);
        float alpha=10.;
        vec3 specular=k_s*pow(dotRV,alpha)*i_s;

        //c=light_color*diffuse*result.color+backgroundColor*0.2;
        c=ambient+diffuse_color+ specular+ backgroundColor*0.2;
        
        
     }
    // Output to screen
     fragColor = vec4(vec3(c),1.0);
}



