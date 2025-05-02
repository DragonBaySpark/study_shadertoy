void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
     // Normalized pixel coordinates (from -1 to 1)
     vec2 uv = (2.0*fragCoord-iResolution.xy)/iResolution.xx;

//    vec2 uv = (2.0*fragCoord-iResolution.xy)/min(iResolution.x,iResolution.y);//取x和y的最小值作为比例
     float c=0.;//默认黑色
     float r=0.3;//圆的半径
      
     c=1.-step(0.,length(uv)-0.5);
    // Output to screen
     fragColor = vec4(vec3(c),1.0);
}