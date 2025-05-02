#define PIXW (1./iResolution.y)

const int MAX_STEPS = 100;
const float START_DIST = 0.001;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;


struct Material {
  vec3 ambientColor; // k_a * i_a
  vec3 diffuseColor; // k_d * i_d
  vec3 specularColor; // k_s * i_s
  float alpha; // shininess
};




struct SDFResult
{
    float d;
    Material mat;
};

Material gold()
{
    return Material(
        vec3(0.7,0.5,0.)*0.5,
        vec3(0.7, 0.7, 0.),
        vec3(1),
        5.
    );
}
Material silver()
{
    return Material(
        vec3(0.8)*0.4,
        vec3(0.7)*0.5,
        vec3(1.)*0.6,
        5.
    );
}

Material checkerboard(vec3 p)
{
    return Material(
        vec3(1. + 0.7*mod(floor(p.x) + floor(p.z), 2.0)) * 0.3,
        vec3(0.3),
        vec3(0),
        1.
    );
}

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

SDFResult sdBox( vec3 p, vec3 b,vec3 offset,Material mat )
{
  vec3 q = abs(p-offset) - b;
  return SDFResult(length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0),mat);
}

vec3 getBackgroundColor(vec2 uv)
{
//uv.y [-1,1]
//y: [0,1] 
    float y=(uv.y+1.)/2.; 
    return mix(vec3(1,0,1),vec3(0,1,1),y);
}

SDFResult sdSphere(vec3 p, float r,vec3 offset,Material mat)
{
    return SDFResult(length(p-offset)-r,mat);
}
SDFResult sdFloor(vec3 p,Material mat)
{
    float d=p.y+1.;
    return SDFResult(d,mat);
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


vec3 phongLighting(vec3 lightDir,vec3 normal,vec3 rd,vec3 viewDir,Material material)
{
    vec3 ambientColor = material.ambientColor;
    //计算漫反射
    vec3 diffuse = material.diffuseColor * max(dot(normal, lightDir), 0.0);
    //计算镜面反射
    vec3 reflectDir = reflect(-lightDir, normal);
    
    float specular = pow(max(dot(reflectDir, viewDir), 0.0), material.alpha);
    vec3 specularColor = material.specularColor * specular;
    return ambientColor + diffuse + specularColor;
   // return diffuse + specularColor;
}

SDFResult sdScene(vec3 p)
{
    
    SDFResult result1=sdSphere(p,0.5,vec3(-0.6,0.,0.),gold());
    SDFResult result2=sdSphere(p,0.5,vec3(0.6,0.,0.),silver());
    //SDFResult result3=sdBox(p,vec3(1.,1.0,1.),vec3(4,0.2,-4),vec3(0.,0.,1.));
    
    SDFResult result=minWithColor(result1,result2);
    //result=minWithColor(result,result3);

    
    result=minWithColor(result, sdFloor(p,checkerboard(p)));
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
float shadowRay(vec3 ro, vec3 rd) {
    // ro: 射线起点(表面点)
    // rd: 射线方向(指向光源)
    float t = MIN_DIST;
    float res = 1.0; // 1.0表示完全照亮，0.0表示完全阴影
    
    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * t;
        float h = sdScene(p).d; // 场景SDF函数
        
        if(h < EPSILON) {
            return 0.0; // 完全阴影
        }
        
        t += h;
        if(t >= MAX_DIST) break;
    }
    
    return res;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
     // Normalized pixel coordinates (from -1 to 1)
     //vec2 uv = (2.0*fragCoord-iResolution.xy)/iResolution.xx;
     vec2 uv = (fragCoord-0.5*iResolution.xy)/iResolution.y;

     
     

     //vec3 backgroundColor = vec3(0.835, 1, 1);
     vec3 backgroundColor = mix(vec3(1, .341, .2), vec3(0, 1, 1), uv.y) * 1.6;
     //vec3 c=getBackgroundColor(uv);
     vec3 c=backgroundColor;
     vec3 lp=vec3(0,0.,0.);
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
  
        vec3 p=ro+rd*d;
        vec3 n=calcNormal(p);
        
        //vec3 lightPosition=vec3(2,2,7);
        //vec3 lightPosition1=vec3(-8,-6,-5);
        vec3 lightPosition1 = vec3(cos(iTime), 2, sin(iTime));

        vec3 lightDirection1 = normalize(lightPosition1 - p);
        
        c=phongLighting(lightDirection1,n,rd,normalize(ro-p),result.mat);
        
       // vec3 lightPosition2=vec3(1,1,1);
      //  c+=phongLighting(normalize(lightPosition2-p),n,rd,normalize(ro-p),result.mat);

        vec3 newOrigin=p+n*0.01; 
        
        float shadow = shadowRay(newOrigin,lightDirection1);
        c*=shadow;
        c=pow(c,vec3(1.0/2.2)); // gamma校正
        
     }
    // Output to screen
     fragColor = vec4(vec3(c),1.0);
}



