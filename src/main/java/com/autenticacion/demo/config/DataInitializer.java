package com.autenticacion.demo.config;

import com.autenticacion.demo.model.Rol;
import com.autenticacion.demo.model.Usuario;
import com.autenticacion.demo.repository.RolRepository;
import com.autenticacion.demo.repository.UsuarioRepository;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
public class DataInitializer {

    @Bean
    public CommandLineRunner initData(UsuarioRepository usuarioRepository, RolRepository rolRepository,
            PasswordEncoder passwordEncoder) {
        return args -> {
            // Crear Rol ADMIN si no existe
            Rol adminRole = rolRepository.findByNombre("ADMIN").orElseGet(() -> {
                Rol rol = new Rol();
                rol.setNombre("ADMIN");
                rol.setDescripcion("Administrador del sistema");
                return rolRepository.save(rol);
            });

            // Crear Usuario Admin si no existe
            if (usuarioRepository.findByEmailIgnoreCase("admin@example.com").isEmpty()) {
                Usuario admin = new Usuario();
                admin.setNombre("Admin");
                admin.setApellido("User");
                admin.setEmail("admin@example.com");
                admin.setPassword(passwordEncoder.encode("password"));
                admin.setEstado("ACTIVO");
                admin.setRol(adminRole);
                usuarioRepository.save(admin);
                System.out.println("Usuario admin creado: admin@example.com / password");
            }
        };
    }
}
