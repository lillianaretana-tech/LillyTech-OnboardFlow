# Configuración de accesos reales

1. Ejecute en Supabase, en orden: `01_onboardflow_v0.5.sql`, `02_hr_management_rls.sql` y `03_auth_roles_and_portals.sql`.
2. En Authentication > Users, cree una cuenta por persona. No comparta contraseñas.
3. Copie el UUID de cada usuario y cree su perfil con el mismo UUID:

```sql
insert into public.of_profiles(id,tenant_id,full_name,role)
values ('UUID_AUTH','UUID_EMPRESA','Nombre completo','supervisor');
```

Roles admitidos: `owner`, `admin`, `hr`, `supervisor` y `candidate`.

Para candidatos, además vincule la cuenta con su expediente:

```sql
update public.of_people
set auth_user_id='UUID_AUTH'
where tenant_id='UUID_EMPRESA' and document_id='IDENTIFICACION';
```

El inicio único es `index.html`. Supabase redirige automáticamente según el rol. La contraseña antigua `LillyTech2026` dejó de utilizarse.
