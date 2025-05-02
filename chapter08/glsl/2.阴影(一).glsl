const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float PRECISION = 0.001;
const float EPSILON = 0.0005;

float sdSphere(vec3 p, float r, vec3 offset)
{
  return length(p - offset) - r;
}

float sdFloor(vec3 p) {
  return p.y + 1.;
}

float scene(vec3 p) {
  float co = min(sdSphere(p, 1., vec3(0, 0, -2)), sdFloor(p));
  return co;
}

float rayMarch(vec3 ro, vec3 rd) {
  float depth = MIN_DIST;
  float d; // distance ray has travelled

  for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
    vec3 p = ro + depth * rd;
    d = scene(p);
    depth += d;
    if (d < PRECISION || depth > MAX_DIST) break;
  }

  d = depth;

  return d;
}

float shadowRay(vec3 ro, vec3 rd) {
    // ro: 射线起点(表面点)
    // rd: 射线方向(指向光源)
    float t = MIN_DIST;
    float res = 1.0; // 1.0表示完全照亮，0.0表示完全阴影
    
    for(int i = 0; i < MAX_MARCHING_STEPS; i++) {
        vec3 p = ro + rd * t;
        float h = scene(p); // 场景SDF函数
        
        if(h < PRECISION) {
            return 0.0; // 完全阴影
        }
        
        t += h;
        if(t >= MAX_DIST) break;
    }
    
    return res;
}

vec3 calcNormal(in vec3 p) {
    vec2 e = vec2(1, -1) * EPSILON;
    return normalize(
      e.xyy * scene(p + e.xyy) +
      e.yyx * scene(p + e.yyx) +
      e.yxy * scene(p + e.yxy) +
      e.xxx * scene(p + e.xxx));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
  vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
  vec3 backgroundColor = vec3(0);

  vec3 col = vec3(0);
  vec3 ro = vec3(0, 0, 3); // ray origin that represents camera position
  vec3 rd = normalize(vec3(uv, -1)); // ray direction

  float sd = rayMarch(ro, rd); // signed distance value to closest object

  if (sd > MAX_DIST) {
    col = backgroundColor; // ray didn't hit anything
  } else {
    vec3 p = ro + rd * sd; // point discovered from ray marching
    vec3 normal = calcNormal(p); // surface normal

    vec3 lightPosition = vec3(cos(iTime), 2, sin(iTime));
    vec3 lightDirection = normalize(lightPosition - p);

    float dif = clamp(dot(normal, lightDirection), 0., 1.); // diffuse reflection clamped between zero and one

    vec3 newOrigin=p;
    float newDepth=rayMarch(newOrigin,lightDirection);
    float shadow = shadowRay(newOrigin,lightDirection);
    dif *= shadow;
    col = vec3(dif);
  }

  fragColor = vec4(col, 1.0);
}