# Autenticación y Autorización — JWT

Implementación de un sistema de autenticación y autorización usando **Spring Security**, enfocada en JSON Web Tokens (JWT), con control de acceso basado en roles.

---

## Objetivo de esta implementación

Esta rama demuestra:

- Cómo implementar autenticación stateless con JWT en Spring Security
- Qué problemas resuelve este enfoque en arquitecturas distribuidas
- Qué limitaciones tiene frente a la autenticación basada en sesión

---

## Enfoque de autenticación

### JWT (JSON Web Token)

El estado de autenticación se almacena **en el cliente** como un token firmado criptográficamente.

**Flujo de validación:**

- El cliente envía el token JWT en el header `Authorization: Bearer <token>`
- Un filtro personalizado (`JwtRequestFilter`) intercepta cada petición
- Se valida la firma y expiración del token sin consultar base de datos
- Si es válido, se establece la autenticación en el `SecurityContextHolder`

**Componentes clave:**

- `JwtRequestFilter`: Filtro que valida el token en cada request
- `JwtUtil`: Clase de utilidad para generar, firmar y validar tokens
- `SecurityConfig`: Configura `SessionCreationPolicy.STATELESS`

**Almacenamiento de estado:**

- Servidor: Ninguno (stateless)
- Cliente: Token JWT con claims (email, rol, expiración)

---

## Decisiones de diseño

> **Nota importante**: Esta implementación está pensada como una **API HTTP stateless** y no como una aplicación web basada en navegador. Por eso no usa cookies, no requiere protección CSRF, y no implementa form login tradicional.

**Qué habilita técnicamente JWT:**

- **Stateless en Spring Security**: Configuración `SessionCreationPolicy.STATELESS` elimina la necesidad de HttpSession
- **Verificación criptográfica**: Cada token se valida con firma HMAC-SHA256 sin consultar base de datos
- **Claims embebidos**: Email, rol y expiración viajan en el token, evitando lookups adicionales
- **Filtro personalizado**: `JwtRequestFilter` ejecuta antes de `UsernamePasswordAuthenticationFilter` para extraer y validar el token

**Qué problemas resuelve en Spring Security:**

- **Escalabilidad horizontal**: No hay sincronización de sesiones entre instancias (no requiere Redis/JDBC store)
- **APIs REST puras**: Compatible con clientes que no mantienen cookies (mobile apps, SPAs en diferentes dominios)
- **Carga reducida**: La validación de token no accede a base de datos en cada petición

**Trade-offs técnicos:**

- **Logout**: No se puede invalidar un token antes de su expiración. Solución típica: lista negra en Redis (no implementada)
- **Payload**: El token completo (~200-500 bytes) viaja en cada request vs cookie de sesión (~20 bytes)
- **Renovación**: Requiere lógica adicional de refresh tokens para sesiones largas (no implementada)

> Esta implementación prioriza independencia entre requests y escalabilidad automática.

---

## Flujo de autenticación y autorización

```text
Cliente
  |
  | POST /api/auth/login (email, password)
  v
AuthController
  |
  | Autentica con AuthenticationManager
  v
Spring Security (DaoAuthenticationProvider)
  |
  | Valida credenciales con UserDetailsService
  v
JwtUtil.generateToken()
  |
  | Genera token firmado con HS256
  v
Cliente recibe: {"token": "eyJhbG...", "email": "...", "rol": "..."}
  |
  | Cliente almacena token (localStorage, cookie, etc.)
  |
  | GET /api/recurso-protegido
  | Authorization: Bearer eyJhbG...
  v
JwtRequestFilter
  |
  | Extrae y valida token
  | Si válido: establece Authentication en SecurityContext
  v
Controlador protegido
  |
  | Verifica rol con @PreAuthorize (opcional)
  v
Respuesta
```

---

## Roles y autorización

**Roles definidos:**

- `USER`: Usuario estándar
- `ADMIN`: Administrador del sistema

**Ejemplo de autorización por endpoint:**

- Cualquier endpoint protegido requiere token JWT válido
- La autorización por rol se puede implementar con `@PreAuthorize("hasRole('ADMIN')")`

---

## Endpoints principales

| Método | Endpoint           | Autenticación | Rol  |
|--------|--------------------|---------------|------|
| POST   | /api/auth/login    | No            | -    |
| GET    | /api/*             | Sí (JWT)      | USER |

**Ejemplo de petición autenticada:**

```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..." \
     http://localhost:8080/api/recurso
```

---

## Tests

Tests de seguridad implementados con Spring Boot Test y MockMvc:

- Login válido → devuelve token JWT con estructura correcta
- Acceso sin token → 401 Unauthorized
- Acceso con token inválido/manipulado → 401 Unauthorized
- Acceso con token malformado → 401 Unauthorized
- Acceso con rol insuficiente → 403 Forbidden

Los tests validan la configuración de Spring Security, la generación de tokens JWT y los flujos de autorización basados en roles.

**Ejecución:**

```bash
mvn test
```

---

## Ejecución

Ejecución (local)

```bash
mvn spring-boot:run
```

Ejecución (Docker)

- **Construir y levantar:**

```bash
docker compose up --build -d
```

> ejecutar desde la raíz del proyecto

- **Probar endpoint de salud:**

```bash
curl http://localhost:8080/api/auth/test
```

- **Login (usuario seed):**
  - Usuario: `admin@example.com`
  - Contraseña: `password`
  - Petición de ejemplo:

  ```bash
  curl -X POST -H "Content-Type: application/json" -d '{"email":"admin@example.com","password":"password"}' http://localhost:8080/api/auth/login
  ```

Nota: la base de datos MySQL se ejecuta en el mismo `docker compose` y la aplicación se conecta internamente; si necesitas acceder al puerto MySQL desde el host, exporta un puerto distinto en `docker-compose.yml`.

**Requisitos:**

- Java 21
- Base de datos relacional (MySQL 8.0+ como ejemplo)
- Maven 3.6+

**Configuración:**

- Copiar `.env.example` a `.env` y configurar:
  - `JWT_SECRET`: Clave secreta para firmar tokens (mínimo 256 bits)
  - `JWT_EXPIRATION`: Tiempo de expiración en milisegundos (default: 24h)
  - Credenciales de base de datos

**Nota sobre persistencia:**

La persistencia es intercambiable. MySQL se utiliza como ejemplo, pero el diseño usa Spring Data JPA y no depende de características específicas del motor. Puede usar H2, PostgreSQL, MariaDB u otra base de datos relacional compatible modificando `application.properties`.

---

## Limitaciones conocidas

- **No implementa refresh tokens**: los tokens expiran y requieren nuevo login
- **No hay revocación de tokens**: un token válido funciona hasta su expiración
- **No incluye OAuth2**: solo autenticación básica con email/password
- **No almacena historial de sesiones**: no hay trazabilidad de logins activos
- **Sin rate limiting**: susceptible a ataques de fuerza bruta sin protección adicional

Estas limitaciones son intencionales para mantener la implementación simple y educativa.

---

## Aspectos técnicos clave

**Cómo funciona el logout:**

En esta implementación, el logout es del lado del cliente: simplemente descarta el token. El token sigue siendo válido hasta su expiración.

**Estrategias de revocación (no implementadas aquí):**

- Lista negra de tokens en Redis con TTL
- Versioning de tokens por usuario en base de datos
- Reducir tiempo de expiración y usar refresh tokens

**CSRF no es necesario:**

Los tokens JWT en headers `Authorization` no son vulnerables a CSRF porque:

- El navegador no envía headers personalizados automáticamente en requests cross-origin
- No se usan cookies, por lo tanto no hay envío automático de credenciales

Esto contrasta con la autenticación por sesión donde CSRF es crítico.
