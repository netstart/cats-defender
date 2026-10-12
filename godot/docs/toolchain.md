# Toolchain (M20) — versões fixadas

| Ferramenta | Versão | Origem |
|---|---|---|
| Godot | 4.7.2-stable (ed1daf0bf) | godot-bin/Godot_v4.7.2-stable_win64.exe |
| Export templates | 4.7.2-stable | %APPDATA%/Godot/export_templates/4.7.2.stable |
| Android SDK | cmdline-tools 11076708 | C:\android-sdk |
| Build-tools / Platform | 34.0.0 / android-34 | sdkmanager |
| JDK | Microsoft OpenJDK 17.0.20 | C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot |
| Keystore debug | RSA 2048, alias androiddebugkey | build/debug.keystore (gerada por build_install_play.ps1) |
| Emulador AVD | Redmi_Note_14_Pro_Plus_5G (1220x2712, 480dpi, API 34) | tools/setup_emulator.ps1 |

Renderer: Compatibility (OpenGL ES 3). No emulador, usar `-gpu angle_indirect`
(SwiftShader puro falha com GL_MAX_FRAGMENT_UNIFORM_VECTORS).
