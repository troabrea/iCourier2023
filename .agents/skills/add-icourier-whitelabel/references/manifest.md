# Manifest

Pass a JSON document with this shape to `manage_whitelabel.py`:

```json
{
  "slug": "sample",
  "name": "Sample",
  "className": "Sample",
  "bundleId": "com.barolit.sample",
  "appGroup": "group.com.barolit.sample",
  "urlScheme": "sample",
  "companyId": "00000000-0000-4000-8000-000000000000",
  "firebaseProject": "firebase-project-id",
  "iosTeam": "TEAMID",
  "version": "2027.0.2",
  "build": 65,
  "icon": "/absolute/path/to/AppIcon.png",
  "iconBackground": "#FFFFFF",
  "tagline": "",
  "locale": "es-DO",
  "currency": "RD$",
  "weightUnit": "lb",
  "topic": "SAMPLE",
  "fonts": {"head": "Font Display", "body": "Font Text"},
  "radius": {"sm": 8, "md": 16, "lg": 24},
  "palettes": {
    "light": {
      "primary": "#123456",
      "onPrimary": "#FFFFFF",
      "secondary": "#654321",
      "onSecondary": "#FFFFFF"
    },
    "dark": {
      "primary": "#ABCDEF",
      "onPrimary": "#102030",
      "secondary": "#FEDCBA",
      "onSecondary": "#203040"
    }
  },
  "capabilities": {
    "delivery": true,
    "payments": true,
    "points": true,
    "prealerts": true,
    "widgets": true,
    "notifications": true
  },
  "navigation": {
    "tabs": ["news", "branches", "home", "calculator", "more"]
  }
}
```

`className`, locale settings, capabilities, navigation, radii, tagline, topic, and `iconBackground` have standard defaults. Keep them explicit in customer manifests so review does not depend on defaults.
