package com.example.apigatewaymanager.controller;

import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

// In API Gateway project
@RestController
//@CrossOrigin(origins = "http://localhost:5173", allowCredentials = "true")
public class CorsTestController {

    @GetMapping("/test")
    public String test() {
        return "CORS is working!";
    }
}