# u_flutter

u_flutter (package `u`) is shared by every Flutter app, each with different features and a different business. Not all of them use SinaMN75U as their backend (SinApp and AVREEN have their own).

- Everything added or changed here (functionality, features, fixes, anything) must be general purpose. A feature made for one app may later be used by another.
- No app names, business-specific rules or one-app assumptions. Per-app behaviour goes in parameters with neutral defaults, callbacks or configuration.
- Name things after what they do, not after the app that needed them, and keep each feature usable on its own.
- A component, extension or utility that does not need the backend must not depend on SinaMN75U (UServices, its models or endpoints). Backend features stay opt-in, so an app with another backend never has to call them.
- All user-facing text goes in the l10n files. Every key is the camelCase of its English value and is added for every existing language.
