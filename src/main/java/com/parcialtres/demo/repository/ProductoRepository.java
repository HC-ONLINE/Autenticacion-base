package com.parcialtres.demo.repository;

import com.parcialtres.demo.entity.Producto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProductoRepository extends JpaRepository<Producto, Long> {
    
    List<Producto> findByActivoTrue();
    
    List<Producto> findByNombreContainingIgnoreCase(String nombre);
    
    List<Producto> findByStockGreaterThan(Integer stock);
}
