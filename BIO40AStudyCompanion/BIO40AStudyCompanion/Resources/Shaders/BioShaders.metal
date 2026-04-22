#include <metal_stdlib>
using namespace metal;

// All shaders PRESERVE the original color and blend effects on top.
// The mix amount controls visibility — keep it moderate so text stays readable.

// 1. CELL MEMBRANE — Organic flowing color shift on existing pixels
[[ stitchable ]] half4 cellMembrane(float2 position, half4 color, float2 size, float time,
                                     half4 color1, half4 color2) {
    float2 uv = position / size;

    float n = sin(uv.x * 8.0 + time * 0.5) * cos(uv.y * 6.0 + time * 0.3)
            + sin(uv.x * 3.0 - time * 0.7) * cos(uv.y * 4.0 + time * 0.4) * 0.5
            + sin((uv.x + uv.y) * 5.0 + time * 0.2) * 0.3;
    n = n * 0.5 + 0.5;

    float cell = smoothstep(0.3, 0.7, n);
    half4 tint = mix(color1, color2, half(cell));

    // Blend tint with ORIGINAL color — keep original dominant
    half4 result = color;
    result.rgb = mix(color.rgb, tint.rgb, half(0.25));
    return result;
}

// 2. NEURAL PULSE — Rippling rings that brighten/colorize existing content
[[ stitchable ]] half4 neuralPulse(float2 position, half4 color, float2 size, float time,
                                    half4 pulseColor) {
    float2 uv = position / size;
    float2 center = float2(0.5, 0.5);
    float dist = length(uv - center);

    float ring1 = sin(dist * 20.0 - time * 3.0) * 0.5 + 0.5;
    float ring2 = sin(dist * 15.0 - time * 2.5 + 1.5) * 0.5 + 0.5;
    float pulse = smoothstep(0.0, 0.1, ring1 * ring2) * smoothstep(0.8, 0.0, dist);

    half4 result = color;
    result.rgb = mix(color.rgb, pulseColor.rgb, half(pulse * 0.2));
    return result;
}

// 3. BLOOD FLOW — Flowing bright dots across content
[[ stitchable ]] half4 bloodFlow(float2 position, half4 color, float2 size, float time,
                                  half4 flowColor) {
    float2 uv = position / size;

    float flow = 0.0;
    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        float2 p = float2(
            fract(uv.x * 3.0 + fi * 0.2 + time * (0.3 + fi * 0.05)),
            fract(uv.y * 2.0 + fi * 0.3 + sin(time + fi) * 0.1)
        );
        float d = length(p - float2(0.5)) * 4.0;
        flow += smoothstep(1.0, 0.0, d) * 0.2;
    }

    half4 result = color;
    result.rgb = mix(color.rgb, flowColor.rgb, half(flow * 0.35));
    return result;
}

// 4. DNA HELIX — Double helix strands drawn over content
[[ stitchable ]] half4 dnaHelix(float2 position, half4 color, float2 size, float time,
                                 half4 helixColor1, half4 helixColor2) {
    float2 uv = position / size;

    float strand1 = sin(uv.y * 25.0 + time * 2.0) * 0.15 + 0.5;
    float strand2 = sin(uv.y * 25.0 + time * 2.0 + 3.14159) * 0.15 + 0.5;

    float d1 = smoothstep(0.03, 0.0, abs(uv.x - strand1));
    float d2 = smoothstep(0.03, 0.0, abs(uv.x - strand2));

    float crossLink = step(0.9, sin(uv.y * 50.0 + time)) *
                      smoothstep(0.0, 1.0, 1.0 - abs(uv.x - 0.5) * 4.0);
    crossLink *= step(min(strand1, strand2), uv.x) * step(uv.x, max(strand1, strand2));

    half4 result = color;
    result.rgb = mix(color.rgb, helixColor1.rgb, half(d1 * 0.4));
    result.rgb = mix(result.rgb, helixColor2.rgb, half(d2 * 0.4));
    result.rgb = mix(result.rgb, half3(1.0, 1.0, 1.0), half(crossLink * 0.2));
    return result;
}

// 5. ORGANIC GLOW — Pulsing bioluminescent edge glow
[[ stitchable ]] half4 organicGlow(float2 position, half4 color, float2 size, float time,
                                    half4 glowColor) {
    float2 uv = position / size;

    float edgeDist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
    float glow = smoothstep(0.15, 0.0, edgeDist);

    float pulse = sin(time * 1.5) * 0.3 + 0.7;
    float variation = sin(uv.x * 20.0 + time) * sin(uv.y * 15.0 - time * 0.7) * 0.3 + 0.7;

    half4 result = color;
    result.rgb = mix(color.rgb, glowColor.rgb, half(glow * pulse * variation * 0.4));
    return result;
}
