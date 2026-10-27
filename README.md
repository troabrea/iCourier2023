This is the code sample for this video :https://www.youtube.com/watch?v=265JFoIq7iE

## Operación del proyecto

- [Skill onboard-courier](.agents/skills/onboard-courier/SKILL.md): alta Apple y preparación de Google Play. [Guía canónica en el vault](/Users/temis/Vault/Proyectos/iCourier2027/store-onboarding.md).
- [Skill enrrollar-googleplay-signing](.agents/skills/enrrollar-googleplay-signing/SKILL.md): migración de apps existentes, exportación PEPK y separación de firma original y clave de subida.
- [Releases Android por courier](docs/android-releases.md): código Android común, perfiles de firma privados, validación y entregas AAB.
- [Documentación del rediseño](docs/whitelabel-redesign.md).

Para Android, cambiar el código únicamente en `android/release.properties` y
usar `bash tools/build_android_bundle.sh <courier>`. Las firmas reales están en
`android/signing/` (ignorado por Git); `android/signing.example/` contiene las
plantillas sin contraseñas. TUPAQ tiene perfil confirmado `release`; las demás
marcas requieren verificar su asignación en `tools/android_releases.json`.
