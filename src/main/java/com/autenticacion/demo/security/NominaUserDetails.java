package com.autenticacion.demo.security;

import java.util.Collection;
import java.util.List;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import com.autenticacion.demo.model.Usuario;

/**
 * Adaptador de {@link Usuario} al contrato de Spring Security.
 */
public class NominaUserDetails implements UserDetails {

    private final Usuario usuario;

    public NominaUserDetails(Usuario usuario) {
        this.usuario = usuario;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        String roleName = usuario.getRol() != null ? usuario.getRol().getNombre() : "usuario";
        return List.of(new SimpleGrantedAuthority("ROLE_" + roleName.toUpperCase()));
    }

    @Override
    public String getPassword() {
        return usuario.getPassword();
    }

    @Override
    public String getUsername() {
        return usuario.getEmail();
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return !"suspendido".equalsIgnoreCase(usuario.getEstado());
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return "activo".equalsIgnoreCase(usuario.getEstado());
    }

    public Usuario getUsuario() {
        return usuario;
    }
}
