package com.example.demo.controller;

import com.example.demo.model.Product;
import com.example.demo.service.ProductService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Controller for managing product-related operations within the application.
 * Provides REST endpoints for managing products, including retrieval by ID and failure configuration.
 */
@RestController
public class ProductController {

    /**
     * The service layer that handles business logic for product operations. Injected via constructor.
     */
    private final ProductService productService;

    /**
     * Constructor for ProductController.
     * @param productService The service to be injected, managing product-related operations.
     */
    public ProductController(ProductService productService) {
        this.productService = productService;
    }

    /**
     * Retrieves a product by its ID.
     * @param id The ID of the product to retrieve.
     * @return The retrieved product, cached for subsequent requests.
     */
    @GetMapping("/product/{id}")
    @Cacheable("products")
    public Product getProduct(@PathVariable Long id) {
        return productService.getProductById(id);
    }

    /**
     * Endpoint to configure the failure mode of the application.
     * @param fail Boolean flag to turn on/off the failure mode.
     * @return A string indicating the current state of the failure mode.
     */
    @GetMapping("/configure/failure")
    public String configureFailure(@RequestParam boolean fail) {
        productService.setFailForCircuitBreakerTest(fail);
        return "Failure mode is now set to: " + (fail ? "ON" : "OFF");
    }
}
