//package com.example.apigatewaymanager.config;
//
//import org.springframework.context.annotation.Bean;
//import org.springframework.context.annotation.Configuration;
//import org.springframework.web.cors.CorsConfiguration;
//import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
//import org.springframework.web.filter.CorsFilter;
//
//import java.util.Arrays;
//
//@Configuration
//public class CorsConfig {
//
//    @Bean
//    public CorsFilter corsFilter() {
//        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
//        CorsConfiguration config = new CorsConfiguration();
//
//        // Allow credentials
//        config.setAllowCredentials(true);
//
//        // Allow frontend origins
//        config.setAllowedOrigins(Arrays.asList(
//                "http://localhost:5173",
//                "http://localhost:3000",
//                "http://localhost:4173"
//        ));
//
//        // Allow all headers
//        config.setAllowedHeaders(Arrays.asList("*"));
//
//        // Expose headers
//        config.setExposedHeaders(Arrays.asList(
//                "Authorization",
//                "Content-Type"
//        ));
//
//        // Allow all methods
//        config.setAllowedMethods(Arrays.asList(
//                "GET",
//                "POST",
//                "PUT",
//                "DELETE",
//                "PATCH",
//                "OPTIONS"
//        ));
//
//        // Cache preflight for 1 hour
//        config.setMaxAge(3600L);
//
//        // Apply to all routes
//        source.registerCorsConfiguration("/**", config);
//
//        return new CorsFilter(source);
//    }
//}

/// ========== SecurityConfig.java ==========
package com.example.apigatewaymanager.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.convert.converter.Converter;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;


@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .sessionManagement(session -> session
                        .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                )
                .authorizeHttpRequests(authz -> authz
                        // Public endpoints - NO authentication required
                        .requestMatchers(

                                "/actuator/**",           // ✅ FIXED: Allows ALL actuator endpoints including health/liveness
                                "/actuator/health",       // ✅ Base health endpoint
                                "/actuator/health/**",    // ✅ All health sub-endpoints
                                "/actuator/info",
                                "/actuator/health/liveness",   // ← ADD THIS
                                "/actuator/health/readiness",  // ← ADD THIS
                                "/actuator/prometheus",
                                "/actuator/metrics",
                                "/actuator/metrics/**",
                                // Auth endpoints (login, register, etc.)
                                "/api/auth/login",
                                "/api/auth/signup",
                                "/api/auth/refresh",
                                "/api/auth/logout",
                                // Public property browsing
                                "/api/v1/properties/**",
                                "/api/v1/properties/search",
                                "/api/notifications/**",
                                // Confirmation endpoints
                                "/api/v1/appointments/confirm-by-token/**",
                                "/api/bookings/confirm/**"
                        ).permitAll()

                        // All other requests require authentication
                        .anyRequest().authenticated()
                )
                .oauth2ResourceServer(oauth2 -> oauth2
                        .jwt(jwt -> jwt
                                .jwtAuthenticationConverter(jwtAuthenticationConverter())
                        )
                );

        return http.build();
    }

    @Bean
    public JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(jwtGrantedAuthoritiesConverter());
        converter.setPrincipalClaimName("preferred_username");
        return converter;
    }


     //Extract roles from Keycloak JWT token
     //   CRITICAL: Private method to avoid Spring MVC converter registration
    private Converter<Jwt, Collection<GrantedAuthority>> jwtGrantedAuthoritiesConverter() {
        return jwt -> {
            Collection<GrantedAuthority> authorities = new ArrayList<>();

            // Extract roles from realm_access claim
            Map<String, Object> realmAccess = jwt.getClaim("realm_access");
            if (realmAccess != null && realmAccess.containsKey("roles")) {
                @SuppressWarnings("unchecked")
                List<String> roles = (List<String>) realmAccess.get("roles");

                authorities = roles.stream()
                        .map(this::mapRoleToAuthority)
                        .collect(Collectors.toList());
            }

            return authorities;
        };
    }

    /**
     * Map Keycloak role to Spring Security GrantedAuthority
     * Prevents duplicate ROLE_ prefixes
     */
    private GrantedAuthority mapRoleToAuthority(String role) {
        // If role already starts with "ROLE_", use it as-is
        if (role.startsWith("ROLE_")) {
            return new SimpleGrantedAuthority(role);
        }

        // Standard Keycloak internal roles - use as-is
        if (role.startsWith("default-roles-") ||
                role.equals("offline_access") ||
                role.equals("uma_authorization")) {
            return new SimpleGrantedAuthority(role);
        }

        // Custom application roles - add ROLE_ prefix
        return new SimpleGrantedAuthority("ROLE_" + role);
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();

        configuration.setAllowedOrigins(List.of(
                "http://localhost:5173",
                "http://localhost:5174",
                "http://localhost:3000",
                "http://localhost:4173",
                "http://frontend",                 // Docker container name
                "http://frontend:80",              // Docker container with port
                "http://host.docker.internal:5173", // From backend to frontend
                "http://host.docker.internal:5174"  // ← ADD THIS
        ));

        configuration.setAllowedMethods(List.of(
                "GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"
        ));

        configuration.setAllowedHeaders(List.of("*"));

        configuration.setExposedHeaders(List.of(
                "Authorization",
                "Content-Type"
        ));

        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);

        return source;
    }
}


