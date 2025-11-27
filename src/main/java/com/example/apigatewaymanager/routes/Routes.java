package com.example.apigatewaymanager.routes;

import org.springframework.cloud.gateway.server.mvc.handler.GatewayRouterFunctions;
import org.springframework.cloud.gateway.server.mvc.handler.HandlerFunctions;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.web.servlet.function.RequestPredicates;
import org.springframework.web.servlet.function.RouterFunction;
import org.springframework.web.servlet.function.ServerRequest;
import org.springframework.web.servlet.function.ServerResponse;

@Configuration
public class Routes {

    /**
     * Extract JWT from request attribute (set by JwtRelayFilter) or Authorization header
     */
    private String extractJwtToken(ServerRequest request) {
        // First priority: Get JWT from request attribute (set by JwtRelayFilter)
        Object jwtAttribute = request.servletRequest().getAttribute("JWT_TOKEN");

        if (jwtAttribute != null) {
            String token = jwtAttribute.toString();
            System.out.println("✅ DEBUG [Routes]: Found JWT in request attribute");
            return "Bearer " + token;
        }

        // Second priority: Check Authorization header (for requests that bypass filter)
        String authHeader = request.headers().firstHeader(HttpHeaders.AUTHORIZATION);

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            System.out.println("✅ DEBUG [Routes]: Found JWT in Authorization header");
            return authHeader;
        }

        System.out.println("⚠️  DEBUG [Routes]: No JWT token found in request");
        return null;
    }

    // ========== USER SERVICE (Port 8081) - FIXED: user-service-app ==========
    @Bean
    public RouterFunction<ServerResponse> userServiceRoute() {
        return GatewayRouterFunctions.route("user-service")
                // Auth endpoints don't need JWT forwarding (they generate JWTs)
                .route(RequestPredicates.path("/api/auth/**"),
                        HandlerFunctions.http("http://user-service-app:8081"))
                // Internal and user endpoints need JWT
                .route(RequestPredicates.path("/api/internal/**"),
                        HandlerFunctions.http("http://user-service-app:8081"))
                .route(RequestPredicates.path("/api/users/**"),
                        HandlerFunctions.http("http://user-service-app:8081"))
                .before(request -> {
                    String jwtToken = extractJwtToken(request);
                    if (jwtToken != null) {
                        System.out.println("🔄 DEBUG [Routes]: Forwarding JWT to user-service-app");
                        return ServerRequest.from(request)
                                .header(HttpHeaders.AUTHORIZATION, jwtToken)
                                .build();
                    }
                    return request;
                })
                .build();
    }

    // ========== PROPERTY SERVICE (Port 8082) - FIXED: property-service-app ==========
    @Bean
    public RouterFunction<ServerResponse> propertyServiceRoute() {
        return GatewayRouterFunctions.route("property-service")
                .route(RequestPredicates.path("/api/v1/properties/**"),
                        HandlerFunctions.http("http://property-service-app:8082"))
                .before(request -> {
                    String jwtToken = extractJwtToken(request);
                    if (jwtToken != null) {
                        System.out.println("🔄 DEBUG [Routes]: Forwarding JWT to property-service-app");
                        return ServerRequest.from(request)
                                .header(HttpHeaders.AUTHORIZATION, jwtToken)
                                .build();
                    }
                    return request;
                })
                .build();
    }

    // ========== APPOINTMENT SERVICE (Port 8083) - FIXED: appointment-service-app ==========
    @Bean
    public RouterFunction<ServerResponse> appointmentServiceRoute() {
        return GatewayRouterFunctions.route("appointment-service")
                .route(RequestPredicates.path("/api/v1/appointments/**"),
                        HandlerFunctions.http("http://appointment-service-app:8083"))
                .before(request -> {
                    String jwtToken = extractJwtToken(request);
                    if (jwtToken != null) {
                        System.out.println("🔄 DEBUG [Routes]: Forwarding JWT to appointment-service-app");
                        return ServerRequest.from(request)
                                .header(HttpHeaders.AUTHORIZATION, jwtToken)
                                .build();
                    }
                    return request;
                })
                .build();
    }

    // ========== BOOKING SERVICE (Port 8084) - FIXED: booking-service-app ==========
    @Bean
    public RouterFunction<ServerResponse> bookingServiceRoute() {
        return GatewayRouterFunctions.route("booking-service")
                .route(RequestPredicates.path("/api/bookings/**"),
                        HandlerFunctions.http("http://booking-service-app:8084"))
                .before(request -> {
                    String jwtToken = extractJwtToken(request);
                    if (jwtToken != null) {
                        System.out.println("🔄 DEBUG [Routes]: Forwarding JWT to booking-service-app");
                        return ServerRequest.from(request)
                                .header(HttpHeaders.AUTHORIZATION, jwtToken)
                                .build();
                    }
                    return request;
                })
                .build();
    }

    // ========== NOTIFICATION SERVICE (Port 8085) - notification-service ==========
    @Bean
    public RouterFunction<ServerResponse> notificationServiceRoute() {
        return GatewayRouterFunctions.route("notification-service")
                .route(RequestPredicates.path("/api/notifications/**"),
                        HandlerFunctions.http("http://notification-service:8085"))
                .before(request -> {
                    String jwtToken = extractJwtToken(request);
                    if (jwtToken != null) {
                        System.out.println("🔄 DEBUG [Routes]: Forwarding JWT to notification-service");
                        return ServerRequest.from(request)
                                .header(HttpHeaders.AUTHORIZATION, jwtToken)
                                .build();
                    }
                    return request;
                })
                .build();
    }
}