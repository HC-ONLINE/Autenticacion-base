package com.proaula.nomina.security;

import com.proaula.nomina.repository.UsuarioRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    private static final Logger LOGGER = LoggerFactory.getLogger(CustomUserDetailsService.class);

    private final UsuarioRepository usuarioRepository;

    public CustomUserDetailsService(UsuarioRepository usuarioRepository) {
        this.usuarioRepository = usuarioRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String username) {
        return usuarioRepository
                .findByEmailIgnoreCase(username)
                .map(NominaUserDetails::new)
                .map(details -> {
                    LOGGER.debug("Autenticando usuario {}", details.getUsername());
                    return details;
                })
                .orElseThrow(() -> new UsernameNotFoundException("No se encontró el usuario con email: " + username));
    }
}
