package com.parcialtres.demo.repository;

import com.parcialtres.demo.entity.Comentario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ComentarioRepository extends JpaRepository<Comentario, Long> {
    
    List<Comentario> findByProductoId(Long productoId);
    
    List<Comentario> findByUsuarioId(Long usuarioId);
    
    List<Comentario> findByProductoIdOrderByFechaCreacionDesc(Long productoId);
}
