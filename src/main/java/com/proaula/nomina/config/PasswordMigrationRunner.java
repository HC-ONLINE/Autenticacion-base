package com.proaula.nomina.config;

import com.proaula.nomina.repository.UsuarioRepository;
import java.util.regex.Pattern;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.security.crypto.password.PasswordEncoder;

@Component
public class PasswordMigrationRunner implements CommandLineRunner {

    private static final Logger LOGGER = LoggerFactory.getLogger(PasswordMigrationRunner.class);
    private static final Pattern BCRYPT_PATTERN = Pattern.compile("^\\$2[aby]\\$.{56}$");

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;

    public PasswordMigrationRunner(UsuarioRepository usuarioRepository, PasswordEncoder passwordEncoder) {
        this.usuarioRepository = usuarioRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void run(String... args) {
        usuarioRepository.findAll().stream()
                .filter(usuario -> needsEncoding(usuario.getPassword()))
                .forEach(usuario -> {
                    String rawPassword = usuario.getPassword();
                    usuario.setPassword(passwordEncoder.encode(rawPassword));
                    LOGGER.info("Password migrado a hash seguro para usuario {}", usuario.getEmail());
                });
    }

    private boolean needsEncoding(String password) {
        if (password == null || password.isBlank()) {
            return false;
        }
        return !BCRYPT_PATTERN.matcher(password).matches();
    }
}
