package com.autenticacion.demo.controller;

import com.autenticacion.demo.model.Rol;
import com.autenticacion.demo.model.Usuario;
import com.autenticacion.demo.repository.RolRepository;
import com.autenticacion.demo.repository.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
@ActiveProfiles("test")
@DisplayName("Tests de integración - Autenticación")
class AuthControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private RolRepository rolRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    private final String TEST_EMAIL = "test@example.com";
    private final String TEST_PASSWORD = "password123";

    @BeforeEach
    void setUp() {
        // Limpiar y crear datos de prueba
        usuarioRepository.deleteAll();
        rolRepository.deleteAll();
        
        // Crear rol
        Rol rol = new Rol();
        rol.setNombre("USUARIO");
        rol.setDescripcion("Rol de usuario básico");
        rol = rolRepository.save(rol);
        
        // Crear usuario
        Usuario usuario = new Usuario();
        usuario.setEmail(TEST_EMAIL);
        usuario.setPassword(passwordEncoder.encode(TEST_PASSWORD));
        usuario.setNombre("Usuario Test");
        usuario.setApellido("Apellido Test");
        usuario.setEstado("ACTIVO");
        usuario.setRol(rol);
        usuarioRepository.save(usuario);
    }

    @Test
    @DisplayName("Login válido crea sesión y redirecciona")
    void testLoginValidoCreaSesion() throws Exception {
        // Dado: usuario válido en la base de datos
        
        // Cuando: se realiza login con credenciales válidas
        var result = mockMvc.perform(post("/auth/login")
                .param("username", TEST_EMAIL)
                .param("password", TEST_PASSWORD)
                .with(csrf()))
                
                // Entonces: valida respuesta 302 (redirect)
                .andExpect(status().is3xxRedirection())
                
                // Valida redirección a página principal
                .andExpect(redirectedUrl("/"))
                
                // Valida que se crea autenticación (equivalente a sesión)
                .andExpect(request -> {
                    var session = request.getRequest().getSession(false);
                    assert session != null : "Sesión no fue creada";
                    
                    var securityContext = session.getAttribute("SPRING_SECURITY_CONTEXT");
                    assert securityContext != null : "SecurityContext no está en sesión";
                })
                
                .andReturn();
        
        // Verificación adicional: que la sesión contenga el usuario autenticado
        var session = result.getRequest().getSession();
        assert session != null;
    }

    @Test
    @DisplayName("Login con credenciales inválidas no crea sesión")
    void testLoginInvalidoNoCreaSesion() throws Exception {
        // Cuando: se intenta login con contraseña incorrecta
        mockMvc.perform(post("/auth/login")
                .param("username", TEST_EMAIL)
                .param("password", "wrongpassword")
                .with(csrf()))
                
                // Entonces: redirecciona a página de login con error
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/auth/login?error"));
    }

    @Test
    @DisplayName("Login sin CSRF token es rechazado")
    void testLoginSinCsrfRechazado() throws Exception {
        // Cuando: se intenta login sin token CSRF
        mockMvc.perform(post("/auth/login")
                .param("username", TEST_EMAIL)
                .param("password", TEST_PASSWORD))
                
                // Entonces: es rechazado con 403 Forbidden
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Login con usuario inexistente falla")
    void testLoginUsuarioInexistenteFalla() throws Exception {
        // Cuando: se intenta login con usuario que no existe
        mockMvc.perform(post("/auth/login")
                .param("username", "noexiste@example.com")
                .param("password", "anypassword")
                .with(csrf()))
                
                // Entonces: redirecciona a login con error
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/auth/login?error"));
    }

    @Test
    @DisplayName("Login con usuario inactivo falla")
    void testLoginUsuarioInactivoFalla() throws Exception {
        // Dado: usuario inactivo
        Usuario usuario = usuarioRepository.findByEmailIgnoreCase(TEST_EMAIL).orElseThrow();
        usuario.setEstado("INACTIVO");
        usuarioRepository.save(usuario);
        
        // Cuando: se intenta login
        mockMvc.perform(post("/auth/login")
                .param("username", TEST_EMAIL)
                .param("password", TEST_PASSWORD)
                .with(csrf()))
                
                // Entonces: falla la autenticación
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/auth/login?error"));
    }

    @Test
    @DisplayName("Acceso sin sesión redirige a login")
    void testAccesoSinSesionRedirectALogin() throws Exception {
        // Cuando: se intenta acceder a ruta protegida sin sesión
        mockMvc.perform(get("/"))
                
                // Then: redirecciona a página de login
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrlPattern("**/auth/login"));
    }

    @Test
    @DisplayName("Acceso con sesión válida retorna 200 OK")
    void testAccesoConSesionValidaRetorna200() throws Exception {
        // Dado: realizar login primero para obtener sesión
        var loginResult = mockMvc.perform(post("/auth/login")
                .param("username", TEST_EMAIL)
                .param("password", TEST_PASSWORD)
                .with(csrf()))
                .andExpect(status().is3xxRedirection())
                .andReturn();
        
        var session = loginResult.getRequest().getSession();
        
        // Cuando: se accede a ruta protegida con sesión válida
        mockMvc.perform(get("/")
                .session((org.springframework.mock.web.MockHttpSession) session))
                
                // Entonces: permite el acceso
                .andExpect(status().isOk())
                
                // Valida que SecurityContext está cargado
                .andExpect(request -> {
                    var securityContext = session.getAttribute("SPRING_SECURITY_CONTEXT");
                    assert securityContext != null : "SecurityContext debe estar en sesión";
                });
    }

    @Test
    @DisplayName("Logout invalida sesión con revocación inmediata")
    void testLogoutInvalidaSesionYRevocaAcceso() throws Exception {
        // Dado: realizar login primero para obtener sesión válida
        var loginResult = mockMvc.perform(post("/auth/login")
                .param("username", TEST_EMAIL)
                .param("password", TEST_PASSWORD)
                .with(csrf()))
                .andExpect(status().is3xxRedirection())
                .andReturn();
        
        var session = (org.springframework.mock.web.MockHttpSession) loginResult.getRequest().getSession();
        assertNotNull(session.getAttribute("SPRING_SECURITY_CONTEXT"), "Sesión debe estar autenticada");
        
        // Cuando: se realiza logout
        mockMvc.perform(post("/logout")
                .session(session)
                .with(csrf()))
                
                // Entonces: logout exitoso
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/auth/login?logout"));
        
        // Valida revocación inmediata: sesión invalidada
        assertTrue(session.isInvalid(), "Sesión debe estar invalidada después del logout");
        
        // Cuando: se intenta acceder con la sesión invalidada
        mockMvc.perform(get("/")
                .session(session))
                
                // Entonces: redirige a login porque sesión ya no es válida
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrlPattern("**/auth/login"));
    }
}
