# GestFlee — Sistema de Gestión de Flota

Aplicación Rails para control de flota vehicular (checklists, mantenimiento,
combustible, incidentes, inventario, auxilio en ruta), multi-empresa por
diseño. Ver [roadmap.md](roadmap.md) para el detalle de qué está construido.

## Requisitos

- Ruby 3.3.12 (ver `.ruby-version`)
- PostgreSQL (local: servicio `postgresql-x64-17`, usuario `postgres`)
- Node.js LTS + Yarn

## Puesta en marcha (primera vez en un computador nuevo)

```powershell
bundle install
yarn install
```

Crear un archivo `.env` en la raíz (no se sube a git) con:

```
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_HOST=localhost
```

Luego:

```powershell
ruby bin/rails db:create
ruby bin/rails db:migrate
ruby bin/rails db:seed
yarn build
yarn build:css
```

Para levantar el servidor: `ruby bin/rails server` (o `bin/dev` si tienes
`sh` disponible, ej. Git Bash, para correr también los watchers de JS/CSS).

**Nota:** el envío real de correos (SMTP) todavía no está configurado —
el código de verificación de 2 pasos y la recuperación de contraseña se
arman bien pero no le llegan a nadie fuera de este computador. Pendiente.

## Usuarios demo (después de `db:seed`)

| Rol | Correo | Clave |
|---|---|---|
| Superadmin | `superadmin@demo.cl` | `password` |
| Admin | `admin@demo.cl` | `password` |
| Chofer | `chofer@demo.cl` | `Password123!` |
| Mecánico | `mecanico@demo.cl` | `Password123!` |
| Analista | `analista@demo.cl` | `Password123!` |

## Flujo de trabajo (somos 2 personas, en varios computadores)

Repositorio: https://github.com/benjafudai/GestfleeV2

1. **Antes de empezar a trabajar:** `git pull`
2. **Al terminar:** `git add .` → `git commit -m "mensaje"` → `git push`
3. Nunca cambies de computador dejando cambios sin subir.

### Primera vez en un computador nuevo

```powershell
git clone https://github.com/benjafudai/GestfleeV2.git
gh auth login --hostname github.com --git-protocol https --web
```

`gh auth login` te va a dar un código y un link — se hace una sola vez por
computador, después `git pull`/`git push` ya no piden credenciales de nuevo.
