////package com.example.apigatewaymanager.config;
////
////import org.springframework.context.annotation.Bean;
////import org.springframework.context.annotation.Configuration;
////import org.springframework.web.cors.CorsConfiguration;
////import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
////import org.springframework.web.filter.CorsFilter;
////
////import java.util.Arrays;
////
////@Configuration
////public class CorsConfig {
////
////    @Bean
////    public CorsFilter corsFilter() {
////        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
////        CorsConfiguration config = new CorsConfiguration();
////
////        // Allow credentials
////        config.setAllowCredentials(true);
////
////        // Allow frontend origins
////        config.setAllowedOrigins(Arrays.asList(
////                "http://localhost:5173",
////                "http://localhost:3000",
////                "http://localhost:4173"
////        ));
////
////        // Allow all headers
////        config.setAllowedHeaders(Arrays.asList("*"));
////
////        // Expose headers
////        config.setExposedHeaders(Arrays.asList(
////                "Authorization",
////                "Content-Type"
////        ));
////
////        // Allow all methods
////        config.setAllowedMethods(Arrays.asList(
////                "GET",
////                "POST",
////                "PUT",
////                "DELETE",
////                "PATCH",
////                "OPTIONS"
////        ));
////
////        // Cache preflight for 1 hour
////        config.setMaxAge(3600L);
////
////        // Apply to all routes
////        source.registerCorsConfiguration("/**", config);
////
////        return new CorsFilter(source);
////    }
////}
//
///// ========== SecurityConfig.java ==========
//package com.example.apigatewaymanager.config;
//
//import org.springframework.context.annotation.Bean;
//import org.springframework.context.annotation.Configuration;
//import org.springframework.core.convert.converter.Converter;
//import org.springframework.security.authentication.AbstractAuthenticationToken;
//import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
//import org.springframework.security.config.annotation.web.builders.HttpSecurity;
//import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
//import org.springframework.security.config.http.SessionCreationPolicy;
//import org.springframework.security.core.GrantedAuthority;
//import org.springframework.security.core.authority.SimpleGrantedAuthority;
//import org.springframework.security.oauth2.jwt.Jwt;
//import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
//import org.springframework.security.web.SecurityFilterChain;
//import org.springframework.web.cors.CorsConfiguration;
//import org.springframework.web.cors.CorsConfigurationSource;
//import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
//
//import java.util.ArrayList;
//import java.util.Collection;
//import java.util.List;
//import java.util.Map;
//import java.util.stream.Collectors;
//
//
//@Configuration
//@EnableWebSecurity
//@EnableMethodSecurity(prePostEnabled = true)
//public class SecurityConfig {
//
//    @Bean
//    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
//        http
//                .csrf(csrf -> csrf.disable())
//                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
//                .sessionManagement(session -> session
//                        .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
//                )
//                .authorizeHttpRequests(authz -> authz
//                        // Public endpoints - NO authentication required
//                        .requestMatchers(
//
//                                "/actuator/**",           // ✅ FIXED: Allows ALL actuator endpoints including health/liveness
//                                "/actuator/health",       // ✅ Base health endpoint
//                                "/actuator/health/**",    // ✅ All health sub-endpoints
//                                "/actuator/info",
//                                "/actuator/health/liveness",   // ← ADD THIS
//                                "/actuator/health/readiness",  // ← ADD THIS
//                                "/actuator/prometheus",
//                                "/actuator/metrics",
//                                "/actuator/metrics/**",
//                                // Auth endpoints (login, register, etc.)
//                                "/api/auth/login",
//                                "/api/auth/signup",
//                                "/api/auth/refresh",
//                                "/api/auth/logout",
//                                // Public property browsing
//                                "/api/v1/properties/**",
//                                "/api/v1/properties/search",
//                                "/api/notifications/**",
//                                // Confirmation endpoints
//                                "/api/v1/appointments/confirm-by-token/**",
//                                "/api/bookings/confirm/**"
//                        ).permitAll()
//
//                        // All other requests require authentication
//                        .anyRequest().authenticated()
//                )
//                .oauth2ResourceServer(oauth2 -> oauth2
//                        .jwt(jwt -> jwt
//                                .jwtAuthenticationConverter(jwtAuthenticationConverter())
//                        )
//                );
//
//        return http.build();
//    }
//
//    @Bean
//    public JwtAuthenticationConverter jwtAuthenticationConverter() {
//        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
//        converter.setJwtGrantedAuthoritiesConverter(jwtGrantedAuthoritiesConverter());
//        converter.setPrincipalClaimName("preferred_username");
//        return converter;
//    }
//
//
//     //Extract roles from Keycloak JWT token
//     //   CRITICAL: Private method to avoid Spring MVC converter registration
//    private Converter<Jwt, Collection<GrantedAuthority>> jwtGrantedAuthoritiesConverter() {
//        return jwt -> {
//            Collection<GrantedAuthority> authorities = new ArrayList<>();
//
//            // Extract roles from realm_access claim
//            Map<String, Object> realmAccess = jwt.getClaim("realm_access");
//            if (realmAccess != null && realmAccess.containsKey("roles")) {
//                @SuppressWarnings("unchecked")
//                List<String> roles = (List<String>) realmAccess.get("roles");
//
//                authorities = roles.stream()
//                        .map(this::mapRoleToAuthority)
//                        .collect(Collectors.toList());
//            }
//
//            return authorities;
//        };
//    }
//
//    /**
//     * Map Keycloak role to Spring Security GrantedAuthority
//     * Prevents duplicate ROLE_ prefixes
//     */
//    private GrantedAuthority mapRoleToAuthority(String role) {
//        // If role already starts with "ROLE_", use it as-is
//        if (role.startsWith("ROLE_")) {
//            return new SimpleGrantedAuthority(role);
//        }
//
//        // Standard Keycloak internal roles - use as-is
//        if (role.startsWith("default-roles-") ||
//                role.equals("offline_access") ||
//                role.equals("uma_authorization")) {
//            return new SimpleGrantedAuthority(role);
//        }
//
//        // Custom application roles - add ROLE_ prefix
//        return new SimpleGrantedAuthority("ROLE_" + role);
//    }
//
//    @Bean
//    public CorsConfigurationSource corsConfigurationSource() {
//        CorsConfiguration configuration = new CorsConfiguration();
//
//        configuration.setAllowedOrigins(List.of(
//                "http://localhost:5173",
//                "http://localhost:5174",
//                "http://localhost:3000",
//                "http://localhost:4173",
//                "http://frontend",                 // Docker container name
//                "http://frontend:80",              // Docker container with port
//                "http://host.docker.internal:5173", // From backend to frontend
//                "http://host.docker.internal:5174"  // ← ADD THIS
//        ));
//
//        configuration.setAllowedMethods(List.of(
//                "GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"
//        ));
//
//        configuration.setAllowedHeaders(List.of("*"));
//
//        configuration.setExposedHeaders(List.of(
//                "Authorization",
//                "Content-Type"
//        ));
//
//        configuration.setAllowCredentials(true);
//        configuration.setMaxAge(3600L);
//
//        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
//        source.registerCorsConfiguration("/**", configuration);
//
//        return source;
//    }
//}
//
//

// Updated for Spring Boot 3.0.5

//package com.example.apigatewaymanager.config;
//
//import org.springframework.context.annotation.Bean;
//import org.springframework.context.annotation.Configuration;
//import org.springframework.core.convert.converter.Converter;
//import org.springframework.security.authentication.AbstractAuthenticationToken;
//import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
//import org.springframework.security.config.web.server.ServerHttpSecurity;
//import org.springframework.security.core.GrantedAuthority;
//import org.springframework.security.core.authority.SimpleGrantedAuthority;
//import org.springframework.security.oauth2.jwt.Jwt;
//import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
//import org.springframework.security.oauth2.server.resource.authentication.ReactiveJwtAuthenticationConverterAdapter;
//import org.springframework.security.web.server.SecurityWebFilterChain;
//import org.springframework.web.cors.CorsConfiguration;
//import org.springframework.web.cors.reactive.CorsConfigurationSource;
//import org.springframework.web.cors.reactive.UrlBasedCorsConfigurationSource;
//import reactor.core.publisher.Mono;
//
//import java.util.ArrayList;
//import java.util.Collection;
//import java.util.List;
//import java.util.Map;
//import java.util.stream.Collectors;
//
//@Configuration
//@EnableWebFluxSecurity
//public class SecurityConfig {
//
//    @Bean
//    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
//        return http
//                .csrf(csrf -> csrf.disable())
//                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
//                .authorizeExchange(exchanges -> exchanges
//                        // CRITICAL: Allow actuator health endpoints without authentication
//                        .pathMatchers("/actuator/health/**").permitAll()
//                        .pathMatchers("/actuator/health").permitAll()
//                        .pathMatchers("/actuator/health/liveness").permitAll()
//                        .pathMatchers("/actuator/health/readiness").permitAll()
//                        .pathMatchers("/actuator/info").permitAll()
//                        .pathMatchers("/actuator/prometheus").permitAll()
//                        .pathMatchers("/actuator/metrics/**").permitAll()
//
//                        // Auth endpoints (login, register, etc.)
//                        .pathMatchers("/api/auth/login").permitAll()
//                        .pathMatchers("/api/auth/signup").permitAll()
//                        .pathMatchers("/api/auth/refresh").permitAll()
//                        .pathMatchers("/api/auth/logout").permitAll()
//
//                        // Public property browsing
//                        .pathMatchers("/api/v1/properties/**").permitAll()
//                        .pathMatchers("/api/v1/properties/search").permitAll()
//
//                        // Public notifications
//                        .pathMatchers("/api/notifications/**").permitAll()
//
//                        // Confirmation endpoints
//                        .pathMatchers("/api/v1/appointments/confirm-by-token/**").permitAll()
//                        .pathMatchers("/api/bookings/confirm/**").permitAll()
//
//                        // All other requests require authentication
//                        .anyExchange().authenticated()
//                )
//                .oauth2ResourceServer(oauth2 -> oauth2
//                        .jwt(jwt -> jwt
//                                .jwtAuthenticationConverter(jwtAuthenticationConverter())
//                        )
//                )
//                .build();
//    }
//
//    @Bean
//    public Converter<Jwt, Mono<AbstractAuthenticationToken>> jwtAuthenticationConverter() {
//        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
//        converter.setJwtGrantedAuthoritiesConverter(jwtGrantedAuthoritiesConverter());
//        converter.setPrincipalClaimName("preferred_username");
//        return new ReactiveJwtAuthenticationConverterAdapter(converter);
//    }
//
//    /**
//     * Extract roles from Keycloak JWT token
//     */
//    private Converter<Jwt, Collection<GrantedAuthority>> jwtGrantedAuthoritiesConverter() {
//        return jwt -> {
//            Collection<GrantedAuthority> authorities = new ArrayList<>();
//
//            // Extract roles from realm_access claim
//            Map<String, Object> realmAccess = jwt.getClaim("realm_access");
//            if (realmAccess != null && realmAccess.containsKey("roles")) {
//                @SuppressWarnings("unchecked")
//                List<String> roles = (List<String>) realmAccess.get("roles");
//
//                authorities = roles.stream()
//                        .map(this::mapRoleToAuthority)
//                        .collect(Collectors.toList());
//            }
//
//            return authorities;
//        };
//    }
//
//    /**
//     * Map Keycloak role to Spring Security GrantedAuthority
//     * Prevents duplicate ROLE_ prefixes
//     */
//    private GrantedAuthority mapRoleToAuthority(String role) {
//        // If role already starts with "ROLE_", use it as-is
//        if (role.startsWith("ROLE_")) {
//            return new SimpleGrantedAuthority(role);
//        }
//
//        // Standard Keycloak internal roles - use as-is
//        if (role.startsWith("default-roles-") ||
//                role.equals("offline_access") ||
//                role.equals("uma_authorization")) {
//            return new SimpleGrantedAuthority(role);
//        }
//
//        // Custom application roles - add ROLE_ prefix
//        return new SimpleGrantedAuthority("ROLE_" + role);
//    }
//
//    @Bean
//    public CorsConfigurationSource corsConfigurationSource() {
//        CorsConfiguration configuration = new CorsConfiguration();
//
//        configuration.setAllowedOrigins(List.of(
//                "http://localhost:5173",
//                "http://localhost:5174",
//                "http://localhost:3000",
//                "http://localhost:4173",
//                "http://frontend",
//                "http://frontend:80",
//                "http://host.docker.internal:5173",
//                "http://host.docker.internal:5174"
//        ));
//
//        configuration.setAllowedMethods(List.of(
//                "GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"
//        ));
//
//        configuration.setAllowedHeaders(List.of("*"));
//
//        configuration.setExposedHeaders(List.of(
//                "Authorization",
//                "Content-Type"
//        ));
//
//        configuration.setAllowCredentials(true);
//        configuration.setMaxAge(3600L);
//
//        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
//        source.registerCorsConfiguration("/**", configuration);
//
//        return source;
//    }
//}



// version 3: TODO: Update to latest version


package com.example.apigatewaymanager.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.convert.converter.Converter;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.web.SecurityFilterChain;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Security Configuration for API Gateway (MVC Version)
 * Works with both Docker and Kubernetes environments
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Value("${spring.security.oauth2.resourceserver.jwt.jwk-set-uri}")
    private String jwkSetUri;

    @Value("${spring.security.oauth2.resourceserver.jwt.issuer-uri}")
    private String issuerUri;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())
                .authorizeHttpRequests(auth -> auth
                        // Actuator endpoints - public
                        .requestMatchers("/actuator/health/**").permitAll()
                        .requestMatchers("/actuator/health").permitAll()
                        .requestMatchers("/actuator/health/liveness").permitAll()
                        .requestMatchers("/actuator/health/readiness").permitAll()
                        .requestMatchers("/actuator/info").permitAll()
                        .requestMatchers("/actuator/prometheus").permitAll()
                        .requestMatchers("/actuator/metrics/**").permitAll()
                        .requestMatchers("/actuator/gateway/**").permitAll()
                        .requestMatchers("/actuator/routes/**").permitAll()

                        // Auth endpoints - public
                        .requestMatchers("/api/auth/login").permitAll()
                        .requestMatchers("/api/auth/signup").permitAll()
                        .requestMatchers("/api/auth/register").permitAll()
                        .requestMatchers("/api/auth/refresh").permitAll()
                        .requestMatchers("/api/auth/logout").permitAll()

                        // Public endpoints
                        .requestMatchers("/api/v1/properties/**").permitAll()
                        .requestMatchers("/api/v1/properties/search").permitAll()
                        .requestMatchers("/api/notifications/**").permitAll()
                        .requestMatchers("/api/v1/appointments/confirm-by-token/**").permitAll()
                        .requestMatchers("/api/bookings/confirm/**").permitAll()

                        // All other requests require authentication
                        .anyRequest().authenticated()
                )
                .oauth2ResourceServer(oauth2 -> oauth2
                        .jwt(jwt -> jwt
                                .jwtAuthenticationConverter(grantedAuthoritiesExtractor())
                                .decoder(jwtDecoder())
                        )
                );

        return http.build();
    }

    /**
     * Custom JWT Decoder - Uses property values for different environments
     * Docker: http://keycloak:8080/...
     * Kubernetes: http://keycloak.student-housing.svc.cluster.local:8080/...
     */
    @Bean
    public JwtDecoder jwtDecoder() {
        NimbusJwtDecoder jwtDecoder = NimbusJwtDecoder
                .withJwkSetUri(jwkSetUri)
                .build();

        // CRITICAL: Accept tokens from localhost issuer
        // This allows frontend login (localhost:8080) to work with gateway validation
        jwtDecoder.setJwtValidator(JwtValidators.createDefaultWithIssuer(issuerUri));

        return jwtDecoder;
    }

    /**
     * Extracts roles from Keycloak JWT and converts them to Spring Security authorities
     */
    private Converter<Jwt, AbstractAuthenticationToken> grantedAuthoritiesExtractor() {
        JwtAuthenticationConverter jwtAuthenticationConverter = new JwtAuthenticationConverter();

        jwtAuthenticationConverter.setJwtGrantedAuthoritiesConverter(jwt -> {
            Collection<GrantedAuthority> authorities = new ArrayList<>();

            // Extract realm_access roles
            Map<String, Object> realmAccess = jwt.getClaim("realm_access");
            if (realmAccess != null && realmAccess.containsKey("roles")) {
                @SuppressWarnings("unchecked")
                List<String> roles = (List<String>) realmAccess.get("roles");
                authorities.addAll(roles.stream()
                        .map(this::mapRoleToAuthority)
                        .collect(Collectors.toList()));
            }

            // Extract resource_access roles (optional)
            Map<String, Object> resourceAccess = jwt.getClaim("resource_access");
            if (resourceAccess != null) {
                resourceAccess.forEach((resource, value) -> {
                    @SuppressWarnings("unchecked")
                    Map<String, Object> resourceValue = (Map<String, Object>) value;
                    if (resourceValue.containsKey("roles")) {
                        @SuppressWarnings("unchecked")
                        List<String> roles = (List<String>) resourceValue.get("roles");
                        authorities.addAll(roles.stream()
                                .map(this::mapRoleToAuthority)
                                .collect(Collectors.toList()));
                    }
                });
            }

            return authorities;
        });

        // Set principal claim to preferred_username
        jwtAuthenticationConverter.setPrincipalClaimName("preferred_username");

        return jwtAuthenticationConverter;
    }

    /**
     * Maps Keycloak roles to Spring Security authorities
     */
    private GrantedAuthority mapRoleToAuthority(String role) {
        // If role already has ROLE_ prefix, keep it
        if (role.startsWith("ROLE_")) {
            return new SimpleGrantedAuthority(role);
        }

        // Skip Keycloak default roles
        if (role.startsWith("default-roles-") ||
                role.equals("offline_access") ||
                role.equals("uma_authorization")) {
            return new SimpleGrantedAuthority(role);
        }

        // Add ROLE_ prefix for custom roles
        return new SimpleGrantedAuthority("ROLE_" + role);
    }
}