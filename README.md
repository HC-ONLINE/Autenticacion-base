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

**Por qué se eligió este enfoque:**

- **Escalabilidad horizontal**: No requiere sincronización de sesiones entre servidores
- **Simplicidad de despliegue**: No hay dependencia de un store de sesiones compartido
- **Interoperabilidad**: El token puede usarse en diferentes servicios/dominios

**Qué se gana:**

- Stateless: cada request es independiente
- Rendimiento: sin necesidad de consultar sesiones en cada petición
- Facilita arquitecturas de microservicios

**Qué se pierde:**

- Control de revocación: no se puede invalidar un token antes de su expiración natural
- Mayor tamaño de payload: el token viaja en cada petición
- Complejidad en renovación: requiere implementar estrategias de refresh tokens

**Qué casos NO cubre bien:**

- Revocación inmediata de acceso (logout, cambio de permisos)
- Gestión de sesiones de larga duración sin refresh tokens
- Auditoría detallada de actividad por sesión

> Esta implementación prioriza escalabilidad y simplicidad operacional sobre control granular de sesiones.

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
| GET    | /api/auth/test     | No            | -    |
| GET    | /api/*             | Sí (JWT)      | USER |

**Ejemplo de petición autenticada:**

```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..." \
     http://localhost:8080/api/recurso
```

---

## Tests

**Estado actual:**

- No se han implementado tests automatizados
- Se requiere testing manual con herramientas como Postman o curl

**Casos a cubrir:**

- Login con credenciales válidas → devuelve token
- Acceso sin token → 401 Unauthorized
- Acceso con token expirado → 401 Unauthorized
- Acceso con token manipulado → 401 Unauthorized

---

## Ejecución

```bash
mvn spring-boot:run
```

**Requisitos:**

- Java 21
- MySQL 8.0+
- Maven 3.6+

**Configuración:**

- Copiar `.env.example` a `.env` y configurar:
  - `JWT_SECRET`: Clave secreta para firmar tokens (mínimo 256 bits)
  - `JWT_EXPIRATION`: Tiempo de expiración en milisegundos (default: 24h)
  - Credenciales de base de datos MySQL

---

## Limitaciones conocidas

- **No implementa refresh tokens**: los tokens expiran y requieren nuevo login
- **No hay revocación de tokens**: un token válido funciona hasta su expiración
- **No incluye OAuth2**: solo autenticación básica con email/password
- **No almacena historial de sesiones**: no hay trazabilidad de logins activos
- **Sin rate limiting**: susceptible a ataques de fuerza bruta sin protección adicional

Estas limitaciones son intencionales para mantener la implementación simple y educativa.

---

## Conclusiones

**Este enfoque es adecuado cuando:**

- Se necesita escalar horizontalmente sin complejidad de sincronización de sesiones
- La arquitectura es distribuida (microservicios, APIs independientes)
- El tiempo de vida de las sesiones es corto o se implementan refresh tokens
- La revocación inmediata de acceso no es crítica

**No es recomendable cuando:**

- Se requiere control estricto de sesiones activas con capacidad de revocación instantánea
- La seguridad requiere auditoría detallada de cada sesión
- Se necesita invalidar acceso inmediatamente por cambio de permisos o logout
- La aplicación es monolítica y no hay planes de distribución
