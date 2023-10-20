package com.contoso.cams.model;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import org.hibernate.annotations.CreationTimestamp;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "support_cases")
@Data
public class SupportCase {
    @Id
    @Column(name = "support_case_id", nullable = false, updatable = false)
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "account_id", nullable = false)
    private Account account;

    @Column(name = "creation_date", nullable = false, updatable = false)
    @CreationTimestamp
    private Date timestamp;

    @Column(name = "description", nullable = false)
    private String description;

    @OneToMany(mappedBy="supportCase")
    @OrderBy("creation_date ASC")
    private List<SupportCaseActivity> activities = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    private SupportCaseQueue queue;

    @Column(name = "assigned_to")
    private String assignedTo;
}
