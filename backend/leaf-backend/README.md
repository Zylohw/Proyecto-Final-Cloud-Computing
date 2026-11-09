# Leaf App — Backend (Express + PostgreSQL)

Backend con:
1. Login (correo + contraseña, contraseñas encriptadas con bcrypt, devuelve JWT).
2. Reset de contraseña (si el correo existe en la base de datos, se permite cambiarla).
3. Registro de usuario nuevo con rol **Comun** por defecto.

---

## 1. Instalar Node.js

Si no tienes Node.js instalado:

1. Ve a https://nodejs.org y descarga la versión **LTS** (recomendada).
2. Instálala (siguiente, siguiente, finalizar).
3. Verifica que quedó instalado abriendo una terminal y ejecutando:
   ```
   node -v
   npm -v
   ```
   Deberías ver un número de versión en ambos (npm viene incluido con Node).

## 2. Instalar PostgreSQL (si no lo tienes)

1. Descarga desde https://www.postgresql.org/download/
2. Durante la instalación anota el usuario (por defecto `postgres`) y la contraseña que configures.
3. Crea la base de datos, por ejemplo con pgAdmin o por consola:
   ```
   createdb leaf_app
   ```

## 3. Correr tu script de base de datos

Ejecuta tu `Script_de_La_Base_de_Datos.sql` contra la base `leaf_app`, y luego el archivo
`seed_roles.sql` incluido aquí (inserta los roles Administrador, Mantenimiento y Comun,
que el backend necesita):

```bash
psql -U postgres -d leaf_app -f Script_de_La_Base_de_Datos.sql
psql -U postgres -d leaf_app -f seed_roles.sql
```

## 4. Instalar las dependencias del proyecto

Desde la carpeta `leaf-backend`, ejecuta:

```bash
npm install
```

Esto instala automáticamente: `express`, `pg`, `bcrypt`, `jsonwebtoken`, `dotenv`, `cors`
(y `nodemon` para desarrollo). No necesitas instalarlos por separado, `npm install`
lee el `package.json` y los descarga todos.

## 5. Configurar variables de entorno

Copia el archivo `.env.example` a `.env`:

```bash
cp .env.example .env
```

Y edita `.env` con los datos reales de tu base de datos:

```
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=leaf_app
DB_USER=postgres
DB_PASSWORD=tu_password_real
JWT_SECRET=escribe_aqui_una_cadena_larga_y_aleatoria
JWT_EXPIRES_IN=8h
```

## 6. Levantar el servidor

Para desarrollo (se reinicia solo al guardar cambios):
```bash
npm run dev
```

Para producción:
```bash
npm start
```

Si todo va bien verás:
```
Servidor corriendo en http://localhost:3000
```

---

## Endpoints disponibles

### POST /api/usuarios/registro
Crea un usuario nuevo con rol **Comun**.

Body (JSON):
```json
{
  "nombre": "Juan Pérez",
  "correo": "juan@correo.com",
  "contrasena": "miClave123"
}
```

### POST /api/auth/login
Valida credenciales y devuelve un token JWT.

Body (JSON):
```json
{
  "correo": "juan@correo.com",
  "contrasena": "miClave123"
}
```

Respuesta:
```json
{
  "mensaje": "Login exitoso",
  "token": "eyJhbGciOi...",
  "usuario": { "id": 1, "nombre": "Juan Pérez", "correo": "juan@correo.com", "rol": "Comun" }
}
```

Para las rutas protegidas (si agregas más adelante), envía el token así:
```
Authorization: Bearer eyJhbGciOi...
```

### POST /api/auth/reset-password
Cambia la contraseña si el correo existe en la base de datos.

Body (JSON):
```json
{
  "correo": "juan@correo.com",
  "nuevaContrasena": "nuevaClave456"
}
```

Si el correo no existe, responde `404` y no se hace ningún cambio.

---

## Estructura del proyecto

```
leaf-backend/
├── server.js                 # Punto de entrada
├── seed_roles.sql            # Inserta los 3 roles iniciales
├── .env.example               # Plantilla de variables de entorno
└── src/
    ├── app.js                # Configuración de Express y rutas
    ├── config/db.js           # Conexión a PostgreSQL (pool)
    ├── controllers/
    │   ├── authController.js  # login, resetPassword
    │   └── userController.js  # registrarUsuario
    ├── middleware/auth.js     # requireAuth, requireRole (JWT)
    ├── routes/
    │   ├── authRoutes.js
    │   └── userRoutes.js
    └── utils/jwt.js           # generarToken, verificarToken
```

## Notas y decisiones de diseño

- **Contraseñas:** se guardan con hash bcrypt (10 salt rounds), nunca en texto plano.
- **Reset de contraseña:** según lo acordado, solo valida que el correo exista en
  `usuarios` (no se implementó envío de correo ni token temporal). Si más adelante
  quieres agregar seguridad extra (código de verificación por correo, pregunta de
  seguridad, etc.), este es el lugar donde se ampliaría (`authController.js`).
- **Autenticación entre requests:** JWT. El middleware `requireAuth` está listo para
  proteger rutas futuras (ej. reportes, lecturas), y `requireRole('Administrador')`
  permite restringir por rol cuando lo necesites.
- **Rol por defecto en registro:** el controlador busca dinámicamente el `id` del
  rol `"Comun"` en la tabla `rol`, por lo que es indispensable correr `seed_roles.sql`
  antes de registrar usuarios.
