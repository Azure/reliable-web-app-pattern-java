package com.contoso.cams.model;

import java.util.ArrayList;
import java.util.List;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "accounts")
@Data
public class Account {

    @Id
    @Column(name = "account_id", nullable = false, updatable = false)
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "address", nullable = false)
    private String address;

    @Column(name = "city", nullable = false)
    private String city;

    @ManyToOne(cascade = CascadeType.ALL)
    @JoinColumn(name = "customer_id", nullable = false)
    private Customer customer;

    @ManyToOne
    @JoinColumn(name = "service_plan_id", nullable = false)
    private ServicePlan servicePlan;

    @Column(name = "active", nullable = false)
    private boolean active;

    @OneToMany(cascade = CascadeType.ALL, fetch = FetchType.LAZY, mappedBy = "account", orphanRemoval = true)
    private List<SupportCase> supportCases = new ArrayList<>();

    public Account(String address, String city, Customer customer, ServicePlan servicePlan, boolean active, List<SupportCase> supportCases) {
        this.address = address;
        this.city = city;
        this.customer = customer;
        this.servicePlan = servicePlan;
        this.active = active;
        this.supportCases = supportCases;
    }

    public Account() {
    }
}
