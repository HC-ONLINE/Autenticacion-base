# AccessManager

Sistema de **autenticación y autorización** desarrollado en Java con Spring Boot y Spring Security.  
El proyecto implementa y compara **dos enfoques de autenticación** ampliamente usados en backend:

- Autenticación **stateless** basada en JSON Web Tokens (JWT)
- Autenticación **stateful** basada en sesiones

El objetivo es analizar las **diferencias, ventajas y limitaciones** de cada enfoque dentro del mismo dominio funcional.

---

## Implementaciones disponibles

Explora las dos implementaciones de autenticación desarrolladas en este proyecto:

### [auth-jwt](../../tree/auth-jwt) - Autenticación JWT

Implementación stateless con tokens JWT. Ideal para:

- Arquitecturas de microservicios
- APIs distribuidas
- Escalabilidad horizontal sin configuración adicional

### [auth-session](../../tree/auth-session) - Autenticación por Sesión

Implementación stateful con sesiones del servidor. Ideal para:

- Control estricto de acceso con revocación inmediata
- Auditoría completa de sesiones activas
- Aplicaciones monolíticas o con pocos servidores

Cada rama incluye su propio README con:

- Decisiones de diseño explicadas
- Flujo de autenticación detallado
- Tests de seguridad implementados
- Trade-offs y limitaciones documentadas

---

## Flujo general de autenticación

```text
Cliente
  |
  | Solicitud de autenticación
  v
Spring Security Filter Chain
  |
  v
Validación de credenciales
  |
  v
JWT / Sesión creada
  |
  v
Acceso a recursos protegidos
```

---

## Comparación JWT vs Sesión

| Aspecto            | JWT (auth-jwt)                         | Sesión (auth-session)                       |
|--------------------|----------------------------------------|---------------------------------------------|
| **Estado**         | Stateless: sin estado en servidor      | Stateful: estado en servidor                |
| **Almacenamiento** | Cliente (token firmado)                | Servidor (sesión HTTP)                      |
| **Escalabilidad**  | Horizontal sin configuración adicional | Requiere sticky sessions o store compartido |
| **Revocación**     | No inmediata (solo por expiración)     | Inmediata (invalidación de sesión)          |
| **Payload**        | Viaja en cada petición (header)        | Solo cookie con ID de sesión                |
| **Validación**     | Verificación criptográfica del token   | Consulta de sesión en memoria/store         |
| **Auditoría**      | Limitada (solo en logs)                | Completa (sesiones activas visibles)        |
| **Casos de uso**   | APIs distribuidas, microservicios      | Aplicaciones monolíticas, control estricto  |

**¿Qué implementación explorar primero?**

- Elige **auth-jwt** si te interesa arquitecturas distribuidas y escalabilidad stateless
- Elige **auth-session** si te interesa control de sesiones y revocación inmediata

---

## Qué aprenderás en este repositorio

- **Diferencias prácticas** entre autenticación stateless (JWT) y stateful (sesión)
- Configuración de **Spring Security** para ambos enfoques
- **Trade-offs** reales: escalabilidad vs control, simplicidad vs revocación
- Implementación de **filtros personalizados** (JWT) vs **form login** (sesión)
- **Tests de seguridad** con MockMvc validando flujos de autenticación y autorización
- Cuándo elegir cada enfoque según el contexto del proyecto

Cada rama incluye tests que validan la configuración de seguridad y documentación técnica explicando las decisiones de diseño.

---

## Ramas del proyecto

Navega a la implementación que quieres explorar:

- [**auth-jwt**](../../tree/auth-jwt) - Autenticación con JWT (stateless)
- [**auth-session**](../../tree/auth-session) - Autenticación con sesión (stateful)

---

## Tecnologías utilizadas

- Java 21
- Spring Boot
- Spring Security
- Maven
- JWT (rama `auth-jwt`)
- Spring Data JPA
- Base de datos relacional (MySQL como ejemplo)

---

## Ejecución

Cada implementación puede ejecutarse de forma independiente desde su rama correspondiente:

```bash
mvn spring-boot:run
```

Para ejecutar tests:

```bash
mvn test
```

---

## Licencia

Este proyecto está licenciado bajo la **Apache License 2.0**.
Consulta el archivo [LICENSE](LICENSE) para más información.

---

## Autor

HC-ONLINE.
