package br.edu.ifsul.taskapi.config;

import br.edu.ifsul.taskapi.entity.User;
import br.edu.ifsul.taskapi.repository.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
public class DataInitializer {

    @Bean
    CommandLineRunner initDatabase(UserRepository userRepository, PasswordEncoder encoder) {
        return args -> {
            if (!userRepository.existsByUsername("admin")) {
                var admin = new User("admin", encoder.encode("admin123"), "Administrador", "ADMIN");
                userRepository.save(admin);
            }
        };
    }
}
