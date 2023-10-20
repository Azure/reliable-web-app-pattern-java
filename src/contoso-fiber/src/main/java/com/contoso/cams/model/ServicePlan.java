package com.contoso.cams.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "service_plans")
@Data
public class ServicePlan {
    @Id
    @Column(name="service_plan_id", nullable = false, updatable = false)
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name="name", nullable = false, unique = true)
    private String name;

    @Column(name="description")
    private String description;

    @Column(name="installation_price")
    private Integer installationPrice;

    @Column(name="monthly_price")
    private Integer monthlyPrice;

    @Column(name="is_default")
    private Boolean isDefault;

    public ServicePlan(String name, String description, Integer installationPrice, Integer monthlyPrice, Boolean isDefault) {
        this.description = description;
        this.installationPrice = installationPrice;
        this.monthlyPrice = monthlyPrice;
        this.isDefault = isDefault;
        this.name = name;
    }

    public ServicePlan() {
    }
}
