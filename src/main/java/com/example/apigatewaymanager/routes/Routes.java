package com.example.apigatewaymanager.routes;

import org.springframework.cloud.gateway.server.mvc.handler.GatewayRouterFunctions;
import org.springframework.cloud.gateway.server.mvc.handler.HandlerFunctions;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.servlet.function.RequestPredicates;
import org.springframework.web.servlet.function.RouterFunction;
import org.springframework.web.servlet.function.ServerResponse;

@Configuration
public class Routes {

    /**
     * Add JWT token to forwarded requests
     */
    private String getJwtToken() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof Jwt) {
            Jwt jwt = (Jwt) authentication.getPrincipal();
            return "Bearer " + jwt.getTokenValue();
        }
        return null;
    }

    // ========== USER SERVICE (Port 8081) ==========
    @Bean
    public RouterFunction<ServerResponse> userServiceRoute() {
        return GatewayRouterFunctions.route("user-service")
                .route(RequestPredicates.path("/api/auth/**"), request -> {
                    // Auth endpoints don't need JWT forwarding (they generate JWTs)
                    return HandlerFunctions.http("http://user-service-app:8081").handle(request);
                })
                .route(RequestPredicates.path("/api/internal/**"), request -> {
                    return HandlerFunctions.http("http://user-service-app:8081").handle(request);
                })
                .build();
    }

    // ========== PROPERTY SERVICE (Port 8082) ==========
    @Bean
    public RouterFunction<ServerResponse> propertyServiceRoute() {
        return GatewayRouterFunctions.route("property-service")
                .route(RequestPredicates.path("/api/v1/properties/**"),
                        HandlerFunctions.http("http://property-service-app:8082"))
                .build();
    }

    // ========== APPOINTMENT SERVICE (Port 8083) ==========
    @Bean
    public RouterFunction<ServerResponse> appointmentServiceRoute() {
        return GatewayRouterFunctions.route("appointment-service")
                .route(RequestPredicates.path("/api/v1/appointments/**"),
                        HandlerFunctions.http("http://appointment-service-app:8083"))
                .build();
    }

    // ========== BOOKING SERVICE (Port 8084) ==========
    @Bean
    public RouterFunction<ServerResponse> bookingServiceRoute() {
        return GatewayRouterFunctions.route("booking-service")
                .route(RequestPredicates.path("/api/bookings/**"),
                        HandlerFunctions.http("http://booking-service:8084"))
                .build();
    }

    // ========== NOTIFICATION SERVICE (Port 8085) ==========
    @Bean
    public RouterFunction<ServerResponse> notificationServiceRoute() {
        return GatewayRouterFunctions.route("notification-service")
                .route(RequestPredicates.path("/api/notifications/**"),
                        HandlerFunctions.http("http://notification-service:8085"))
                .build();
    }
}