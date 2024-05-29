package com.example.demo.controller;

import com.example.demo.controller.ProductController;
import com.example.demo.service.ProductService;
import com.example.demo.model.Product;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.boot.test.context.SpringBootTest;
import static org.mockito.Mockito.when;
import static org.junit.jupiter.api.Assertions.assertEquals;

@SpringBootTest
public class ProductControllerTest {

    @MockBean
    private ProductService productService;

    @Test
    public void testGetProduct() {
        ProductController productController = new ProductController(productService);
        Product expectedProduct = new Product(null, null, null);
        expectedProduct.setId(1L);
        expectedProduct.setName("Test Product");
        expectedProduct.setDescription("Test Description");

        when(productService.getProductById(1L)).thenReturn(expectedProduct);

        Product actualProduct = productController.getProduct(1L);

        assertEquals(expectedProduct, actualProduct);
    }
}