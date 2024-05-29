package com.example.demo.service;

import com.example.demo.model.Product;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import org.springframework.stereotype.Service;

/**
 * Service class for managing products.
 * Utilizes resilience patterns such as Circuit Breaker and Retry to handle potential failures gracefully.
 */
@Service
public class ProductService {
    private boolean failForCircuitBreakerTest = false; // Default is false to not force failures

    /**
     * Retrieves a product by its ID with resilience patterns.
     * @param id the ID of the product.
     * @throws RuntimeException if the simulated failure condition is met.
     * @return the retrieved product or a fallback product if an error occurs.
     */
    @CircuitBreaker(name = "default", fallbackMethod = "fallback")
    @Retry(name = "default")
    public Product getProductById(Long id) {
        // This if statement is used to simulate a service failure for testing purposes.
        // The 'failForCircuitBreakerTest' variable is used to manually trigger a failure.
        // The 'Math.random() > 0.7' condition randomly triggers a failure about 30% of the time.
        // When a failure is triggered, a RuntimeException is thrown with the message "Service failure - Circuit breaker activated".
        if (failForCircuitBreakerTest || Math.random() > 0.7) {
            throw new RuntimeException("Service failure - Circuit breaker activated");
        }
        return new Product(id, "Product Name", "Product Description");
    }

    /**
     * Fallback method for getProductById.
     * Provides a default product when the primary method fails.
     * @param id the ID of the fallback product.
     * @param t the exception that triggered the fallback.
     * @return a fallback product.
     */
    public Product fallback(Long id, Throwable t) {
        return new Product(id, "Fallback Product", "Default Description");
    }

    /**
     * Configures the circuit breaker test to simulate failures.
     * @param fail flag to activate or deactivate failure simulation.
     * @return A statement regarding the failure mode status.
     */
    public void setFailForCircuitBreakerTest(boolean fail) {
        this.failForCircuitBreakerTest = fail;
    }
}
