# Fuentes para pruebas visuales

Rubik, Red Hat Display y Red Hat Text permiten renderizar las marcas que usan
Google Fonts en pruebas sin acceso a red. Se cargan explícitamente mediante
`loadBrandFonts(includeGoogleFamilies: true)`. No forman parte de los assets ni
de las declaraciones de fuentes de producción en `pubspec.yaml`.

Archivos variables oficiales, acompañados de sus licencias SIL OFL 1.1:

- [Rubik](https://github.com/google/fonts/tree/main/ofl/rubik)
- [Red Hat Display](https://github.com/google/fonts/tree/main/ofl/redhatdisplay)
- [Red Hat Text](https://github.com/google/fonts/tree/main/ofl/redhattext)

Las fuentes locales de producción Source Sans 3 y Outfit se cargan desde
`fonts/` en el mismo helper.
