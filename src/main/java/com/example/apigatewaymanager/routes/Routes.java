package com.example.apigateway.routes;

import org.springframework.cloud.gateway.server.mvc.handler.GatewayRouterFunctions;
import org.springframework.cloud.gateway.server.mvc.handler.HandlerFunctions;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.function.*;

@Configuration
public class Routes {


        @Bean
        public RouterFunction<ServerResponse> ProductServiceRoute() {
            return GatewayRouterFunctions.route("product-service")
                    .route(RequestPredicates.path("/api/products"), HandlerFunctions.http("http://localhost:8080"))
                    .route(RequestPredicates.path("/api/products/{id}"), HandlerFunctions.http("http://localhost:8080"))
                    .build();
        }

        @Bean
        public RouterFunction<ServerResponse> OrderServiceRoute() {
            return GatewayRouterFunctions.route("order-service")
                    .route(RequestPredicates.path("/api/orders"), HandlerFunctions.http("http://localhost:8081"))
                    .route(RequestPredicates.path("/api/orders/addToCart"), HandlerFunctions.http("http://localhost:8081"))
                    .build();
        }

        @Bean
        public RouterFunction<ServerResponse> InventoryServiceRoute() {
            return GatewayRouterFunctions.route("inventory-service")
                    .route(RequestPredicates.path("/api/inventories"), HandlerFunctions.http("http://localhost:8082"))
                    .route(RequestPredicates.path("/api/inventories/{id}"), HandlerFunctions.http("http://localhost:8082"))
                    .build();
        }
    }



