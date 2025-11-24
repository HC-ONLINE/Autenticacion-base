package com.parcialtres.demo.controller;

import com.parcialtres.demo.dto.LoginRequest;
import com.parcialtres.demo.dto.LoginResponse;
import com.parcialtres.demo.security.CustomUserDetails;
import com.parcialtres.demo.util.JwtUtil;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Slf4j
public class AuthController {

    private final AuthenticationManager authenticationManager;
    private final JwtUtil jwtUtil;

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest loginRequest) {
        try {
            log.debug("Intento de login para el email: {}", loginRequest.getEmail());

            // Autenticar con email y password
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            loginRequest.getEmail(),
                            loginRequest.getPassword()));

            // Obtener los detalles del usuario autenticado
            CustomUserDetails userDetails = (CustomUserDetails) authentication.getPrincipal();

            // Generar el token JWT
            String token = jwtUtil.generateToken(userDetails.getEmail(), userDetails.getRol());

            log.info("Login exitoso para el usuario: {}", userDetails.getEmail());

            // Devolver la respuesta con el token
            LoginResponse response = new LoginResponse(
                    token,
                    userDetails.getEmail(),
                    userDetails.getUsername(),
                    userDetails.getRol());

            return ResponseEntity.ok(response);

        } catch (BadCredentialsException e) {
            log.error("Credenciales inválidas para el email: {}", loginRequest.getEmail());
            return ResponseEntity.status(401)
                    .body("Credenciales inválidas. Verifique su email y contraseña.");
        } catch (Exception e) {
            log.error("Error durante el login: {}", e.getMessage());
            return ResponseEntity.status(500)
                    .body("Error en el servidor. Intente nuevamente.");
        }
    }

    @GetMapping("/test")
    public ResponseEntity<String> test() {
        return ResponseEntity.ok("El servidor de autenticación está funcionando correctamente");
    }
}
