# Distant BSP depth artifacts (2.3.27)

On AYN Thor, CTF-Face showed black wedges and protruding strips on the opposite
tower while the player moved forward/backward. The driver confirmed a 16-bit
depth buffer on Adreno 740. The old projection uses near=1 and far=32768; at a
camera-space distance of 4096, faces 8 units apart can quantize to the same
16-bit depth value, while 24-bit depth distinguishes them.

Android now requests 24-bit depth. If SDL/EGL cannot create that window, it
retries with 16-bit depth before the existing non-GL fallback. Renderer startup
logs the actual GL_DEPTH_BITS and GPU name. Lighting, shadows, near/far planes
and shader precision are unchanged. Both menu variants share this fix.

Validation on the physical Thor:

- Recorded the original scene and injected short forward/backward stick input.
- Used cloned INIs and temporary camera automation to repeat a 400-unit path
  outside each tower while looking at the opposite tower.
- Recorded both directions with 16/24-bit depth and medium/high vertex precision
  (eight five-second videos, about 299 frames each). The driver confirmed the
  actual depth formats. Changing vertex precision alone retained the rogue
  wedges at 16 bits; the 24-bit recordings removed the observed wedges with the
  original shader. The production change therefore keeps the original shader.
- Rebuilt normal/classic for ARMv7 and ARM64 and compiled automotive Java.
  tools/check_menu_variants.py confirms native/assets/resources/manifest parity.
- Installed the normal 2.3.27 APK (versionCode 48) on Thor; its regular launcher
  starts correctly and logs a 24-bit depth buffer. Temporary startup/camera code
  and the three probe files were removed. The Odin was not used.

This is a visual regression comparison on CTF-Face, not an all-map or long-run
GPU benchmark. The older-driver 16-bit fallback was compiled but not physically
exercised on a device lacking a 24-bit EGL configuration.
