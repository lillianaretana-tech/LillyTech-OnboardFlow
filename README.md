# LillyTech OnboardFlow v0.5

## Archivos
- `candidate.html`: experiencia completa del candidato.
- `supervisor.html`: validación de elegibilidad y envío a RH.
- `admin-login.html`: acceso administrativo de demostración.
- `admin.html`: RH, elegibilidad, inducción y empresas.
- `sql/01_onboardflow_v0.5.sql`: esquema para Supabase general.
- `docs/ALCANCE_V0.5.md`: alcance funcional.

## Demostración
- Código candidato: `K7MR-42`
- Contraseña admin: `LillyTech2026`

## Pruebas de elegibilidad en supervisor.html
- Cédula terminada en `999`: no elegible.
- Cédula terminada en `555`: revisión RH.
- Cualquier otra: apto para continuar.

## Importante
Esta versión es un prototipo funcional con datos simulados. No usar con datos reales hasta conectar Supabase Auth, completar RLS por rol y probar las políticas.
