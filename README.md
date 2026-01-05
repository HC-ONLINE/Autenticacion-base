# Autenticación y Autorización — Sesión

Implementación de un sistema de autenticación y autorización usando **Spring Security**, enfocada en sesiones del servidor, con control de acceso basado en roles.

---

## Objetivo de esta implementación

Esta rama demuestra:

- Cómo implementar autenticación basada en sesiones con Spring Security
- Qué problemas resuelve este enfoque tradicional
- Qué limitaciones tiene frente a la autenticación stateless con JWT

---

## Enfoque de autenticación

### Sesión (HTTP Session)

El estado de autenticación se almacena **en el servidor** y se identifica mediante un ID de sesión enviado al cliente en una cookie.

**Flujo de validación:**

- El cliente envía la cookie `JSESSIONID` automáticamente en cada petición
- Spring Security busca la sesión en el servidor usando el ID
- Si existe y es válida, recupera el `Authentication` almacenado
- El `SecurityContext` se carga con la autenticación de la sesión

**Componentes clave:**

- `SecurityFilterChain`: Configura `formLogin()` para autenticación basada en formularios
- `CustomUserDetailsService`: Carga los detalles del usuario desde la base de datos
- `SessionCreationPolicy.IF_REQUIRED`: Spring crea sesión si es necesaria (default)

**Almacenamiento de estado:**

- Servidor: Sesión HTTP con `Authentication` completo
- Cliente: Cookie `JSESSIONID` con ID de sesión

---

## Decisiones de diseño

**Por qué se eligió este enfoque:**

- **Control total sobre sesiones**: se pueden invalidar, renovar o consultar en cualquier momento
- **Simplicidad conceptual**: modelo tradicional bien entendido y documentado
- **Gestión de estado**: el servidor tiene visibilidad completa de las sesiones activas
- **Revocación inmediata**: un logout invalida la sesión en el servidor instantáneamente

**Qué se gana:**

- Revocación instantánea de acceso (logout real, cambio de permisos)
- Auditoría detallada: se puede consultar quién está conectado y desde cuándo
- Menos procesamiento por request: no hay validación criptográfica de tokens
- Menor superficie de ataque en el cliente: solo un ID de sesión opaco

**Qué se pierde:**

- Escalabilidad horizontal sin estado compartido: requiere sticky sessions o store distribuido
- Mayor complejidad en despliegues distribuidos (Redis, bases de datos para sesiones)
- Acoplamiento al servidor: la sesión vive solo en el backend que la creó
- Menor interoperabilidad entre servicios distintos

**Qué casos NO cubre bien:**

- Arquitecturas de microservicios distribuidos sin estado compartido
- APIs públicas consumidas por clientes no web (mobile apps, servicios externos)
- Escalado horizontal sin infraestructura de sesiones compartidas

> Esta implementación prioriza control y revocación inmediata sobre escalabilidad stateless.

---

## Flujo de autenticación y autorización

```text
Cliente (Navegador)
  |
  | GET /auth/login
  v
AuthController
  |
  | Muestra formulario de login (Thymeleaf)
  |
  | POST /auth/login (username, password)
  v
Spring Security Filter Chain
  |
  | UsernamePasswordAuthenticationFilter
  v
AuthenticationManager
  |
  | Valida credenciales con CustomUserDetailsService
  v
SecurityContext
  |
  | Guarda Authentication en sesión HTTP
  |
  | Crea cookie JSESSIONID
  v
Redirección a página principal (/)
  |
  | Cliente envía JSESSIONID en cookie
  v
SecurityContextPersistenceFilter
  |
  | Carga Authentication desde sesión
  v
HomeController
  |
  | Accede a @AuthenticationPrincipal
  v
Página protegida
```

---

## Roles y autorización

**Roles definidos:**

- `USER`: Usuario estándar del sistema
- `ADMIN`: Administrador con privilegios elevados

**Configuración de acceso:**

- Rutas públicas: `/auth/login`, `/css/**`, `/js/**`, `/images/**`
- Rutas protegidas: Cualquier otra requiere autenticación
- Autorización adicional por rol se puede implementar con `@PreAuthorize`

---

## Endpoints principales

| Método | Endpoint           | Autenticación | Rol  |
|--------|--------------------|---------------|------|
| GET    | /auth/login        | No            | -    |
| POST   | /auth/login        | No            | -    |
| GET    | /                  | Sí (Sesión)   | USER |
| POST   | /logout            | Sí            | USER |

**Ejemplo de acceso:**

```bash
# Login (crea sesión y devuelve cookie)
curl -X POST http://localhost:8080/auth/login \
     -d "username=usuario@example.com&password=123456" \
     -c cookies.txt

# Acceso a recurso protegido (envía cookie)
curl http://localhost:8080/ -b cookies.txt
```

---

## Tests

Tests de seguridad implementados con Spring Boot Test y MockMvc:

- Login válido → crea sesión y redirige a página principal
- Login con credenciales inválidas → redirige a login con error
- Acceso sin sesión → redirige a /auth/login
- Acceso con sesión válida → 200 OK
- Logout → invalida sesión con revocación inmediata
- Login sin CSRF token → 403 Forbidden
- Usuario inactivo → rechaza autenticación

Los tests validan la configuración de Spring Security, el ciclo de vida de las sesiones y la revocación inmediata de acceso al hacer logout.

**Ejecución:**

```bash
mvn test
```

---

## Ejecución

```bash
mvn spring-boot:run
```

**Requisitos:**

- Java 21
- Base de datos relacional (MySQL 8.0+ como ejemplo)
- Maven 3.6+

**Configuración:**

- Configurar credenciales de base de datos en `application.properties`
- Las sesiones se almacenan en memoria por defecto
- Para producción, considerar almacenamiento distribuido (Redis, JDBC)

**Nota sobre persistencia:**

La persistencia es intercambiable. MySQL se utiliza como ejemplo, pero el diseño usa Spring Data JPA y no depende de características específicas del motor. Puede usar H2, PostgreSQL, MariaDB u otra base de datos relacional compatible modificando `application.properties`.

**Acceso:**

- Aplicación: [http://localhost:8080](http://localhost:8080)
- Login: [http://localhost:8080/auth/login](http://localhost:8080/auth/login)

---

## Limitaciones conocidas

- **Sesiones en memoria**: no sobreviven reinicios del servidor
- **No escala horizontalmente sin configuración adicional**: requiere sticky sessions o store compartido
- **Acoplada al navegador**: las cookies HTTP no funcionan bien con clientes móviles nativos
- **No implementa "Remember Me"**: la sesión expira según timeout configurado
- **Sin gestión de sesiones concurrentes**: no limita logins simultáneos del mismo usuario

Estas limitaciones son intencionales para mantener la implementación simple y educativa.

---

## Conclusiones

**Este enfoque es adecuado cuando:**

- La aplicación es monolítica o tiene pocos servidores con sticky sessions
- Se requiere control estricto y revocación inmediata de acceso
- Los clientes son navegadores web (no APIs públicas o mobile apps)
- Se necesita auditoría completa de sesiones activas
- La infraestructura soporta almacenamiento de sesiones compartido (Redis, base de datos)

**No es recomendable cuando:**

- Se necesita escalar horizontalmente sin estado compartido
- La arquitectura es de microservicios distribuidos
- Los clientes son aplicaciones móviles nativas o servicios externos
- Se requiere interoperabilidad entre múltiples servicios independientes
- El tráfico es altamente variable y requiere escalado dinámico
