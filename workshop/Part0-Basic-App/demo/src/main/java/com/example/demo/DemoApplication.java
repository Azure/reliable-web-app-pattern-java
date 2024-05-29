package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * The main application class that serves as the entry point for the Spring Boot application.
 * It utilizes the Spring Boot framework to simplify the configuration and deployment of the application.
 */
@SpringBootApplication
public class DemoApplication {

    /**
     * Main method which launches the Spring Boot application.
     * @param args Command line arguments passed during the start of the application.
     */
    public static void main(String[] args) {
        // Run the Spring Boot application, using DemoApplication class as the configuration source.
        SpringApplication.run(DemoApplication.class, args);
    }
}
