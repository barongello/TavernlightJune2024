// DISCLAIMER
// 
// I am no expert at shaders and it is my first attempt to create such effect. So,
// as long as I replicated the desired effect, it is probably not the right way of
// achieving it. I hope my efforts are taken into account (laughing with a tear)
//
// It was based on the already existing Outfit - Outline fragment shader from the
// Mehah's OT Client



uniform sampler2D u_Tex0;               // Player texture
varying vec2      v_TexCoord;           // Texture coordinates
uniform float     u_Time;               // Ellapsed time

const float       offset = 1.0 / 256.0; // Offset to check for empty pixels

void main()
{
  // Sample the current pixel
  vec4 color = texture2D(u_Tex0, v_TexCoord);

  // If it is more opaque than transparent, just draw it
  if (color.a > 0.5)
  {
    gl_FragColor = color;
  }
  // Otherwise, check if it is opaque and all four neighbours are transparent. If
  // it is not opaque or all four neighbours are transparent, draw it. Otherwise,
  // paint it red
  else
  {
    float a =
      texture2D(u_Tex0, vec2(v_TexCoord.x + offset, v_TexCoord.y         )).a +
      texture2D(u_Tex0, vec2(v_TexCoord.x         , v_TexCoord.y - offset)).a +
      texture2D(u_Tex0, vec2(v_TexCoord.x - offset, v_TexCoord.y         )).a +
      texture2D(u_Tex0, vec2(v_TexCoord.x         , v_TexCoord.y + offset)).a;

    if (color.a < 1.0 && a > 0.0)
    {
      gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
    }
    else
    {
      gl_FragColor = color;
    }
  }
}
