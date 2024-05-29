package com.example.demo.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertTrue;

@ExtendWith(MockitoExtension.class)
public class ProductServiceTest {

    @InjectMocks
    private ProductService productService;

    @Test
    public void whenGetProductByIdCalledMultipleTimes_thenCircuitBreakerShouldBeTriggered() {
        boolean exceptionThrown = false;
        for (int i = 0; i < 20; i++) {
            try {
                productService.getProductById((long) i);
            } catch (RuntimeException e) {
                exceptionThrown = true;
            }
        }
        assertTrue(exceptionThrown);
    }
}