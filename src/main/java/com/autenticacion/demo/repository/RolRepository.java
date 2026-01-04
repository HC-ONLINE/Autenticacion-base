package com.autenticacion.demo.repository;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

import com.autenticacion.demo.model.Rol;

public interface RolRepository extends JpaRepository<Rol, Long> {
    Optional<Rol> findByNombre(String nombre);
}
