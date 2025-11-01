package com.proaula.nomina.repository;

import com.proaula.nomina.model.Usuario;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UsuarioRepository extends JpaRepository<Usuario, Long> {
    @EntityGraph(attributePaths = {"rol", "empresa"})
    Optional<Usuario> findByEmailIgnoreCase(String email);
}
