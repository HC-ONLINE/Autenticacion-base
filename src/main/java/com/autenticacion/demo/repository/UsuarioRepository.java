package com.autenticacion.demo.repository;

import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import com.autenticacion.demo.model.Usuario;

public interface UsuarioRepository extends JpaRepository<Usuario, Long> {
    @EntityGraph(attributePaths = { "rol" })
    Optional<Usuario> findByEmailIgnoreCase(String email);
}
