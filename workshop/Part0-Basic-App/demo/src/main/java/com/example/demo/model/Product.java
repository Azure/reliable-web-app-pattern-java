package com.example.demo.model;

/**
 * Represents a product in the system.
 * Contains detailed information such as the product's ID, name, and description.
 */
public class Product {
    private Long id;
    private String name;
    private String description;

    /**
     * Constructor for creating a new Product.
     * @param id The unique identifier for the product.
     * @param name The name of the product.
     * @param description A detailed description of the product.
     */
    public Product(Long id, String name, String description) {
        this.id = id;
        this.name = name;
        this.description = description;
    }

    /**
     * Gets the product's ID.
     * @return The ID of the product.
     */
    public Long getId() {
        return id;
    }

    /**
     * Sets the product's ID.
     * @param id The new ID of the product.
     */
    public void setId(Long id) {
        this.id = id;
    }

    /**
     * Gets the name of the product.
     * @return The name of the product.
     */
    public String getName() {
        return name;
    }

    /**
     * Sets the name of the product.
     * @param name The new name of the product.
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * Gets a detailed description of the product.
     * @return The description of the product.
     */
    public String getDescription() {
        return description;
    }

    /**
     * Sets a new description for the product.
     * @param description The new description of the product.
     */
    public void setDescription(String description) {
        this.description = description;
    }
}
