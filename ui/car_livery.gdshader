shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
uniform vec4 ink : source_color = vec4(1.0);
uniform int pattern = 1;
uniform vec3 panel_offset;
uniform float body_top = 0.86;
varying vec3 p;
varying vec3 n;
void vertex() {
 p = VERTEX + panel_offset;
 n = NORMAL;
 VERTEX += NORMAL * 0.004;
}
float bolt(vec2 q) {
 vec2 points[6] = vec2[6](vec2(0.12,-0.5), vec2(-0.32,0.06), vec2(-0.04,0.06), vec2(-0.16,0.5), vec2(0.34,-0.12), vec2(0.04,-0.12));
 bool inside = false;
 for (int i=0, j=5; i<6; j=i, i++) {
  vec2 a=points[i]; vec2 b=points[j];
  if ((a.y>q.y)!=(b.y>q.y) && q.x<(b.x-a.x)*(q.y-a.y)/(b.y-a.y)+a.x) { inside=!inside; }
 }
 return inside ? 1.0 : 0.0;
}
void fragment() {
 float mask=0.0;
 float top = step(0.38,n.y);
 float side = step(0.82,abs(n.x)) * step(p.y,body_top-0.08) * step(body_top-0.43,p.y);
 if (pattern==1) {
  mask=top*step(0.065,abs(p.x))*step(abs(p.x),0.255);
  mask=max(mask,side*step(abs(p.y-(body_top-0.29)),0.055));
 } else if (pattern==2) {
  mask=top*step(0.035,abs(p.x))*step(abs(p.x),0.19);
  mask=max(mask,step(0.65,abs(n.x))*step(p.y,body_top)*bolt(vec2((p.z-0.46)*1.8,-(p.y-body_top+0.17)*2.3)));
 } else if (pattern==3) {
  float checks=mod(floor((p.x+0.48)/0.16)+floor((p.z+2.0)/0.16),2.0);
  mask=top*step(abs(p.x),0.48)*checks;
  mask=max(mask,side*step(0.3,p.z)*mod(floor(p.z/0.14)+floor(p.y/0.14),2.0));
 }
 if (pattern==4) {
  float streak=p.x+(p.y-1.0)*0.38;
  mask=step(n.z,-0.5)*max(step(abs(streak+0.12),0.055),step(abs(streak+0.29),0.022))*0.38;
 }
 ALBEDO=ink.rgb;
 ROUGHNESS=0.43;
 ALPHA=mask;
}
