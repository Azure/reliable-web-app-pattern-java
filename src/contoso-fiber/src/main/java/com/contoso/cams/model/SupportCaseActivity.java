package com.contoso.cams.model;

import java.util.Date;

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
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "support_case_activities")
@Data
public class SupportCaseActivity {
    @Id
    @Column(name = "activity_id", nullable = false, updatable = false)
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "support_case_id", nullable = false)
    private SupportCase supportCase;

    @Column(name = "creation_date", nullable = false, updatable = false)
    @CreationTimestamp
    private Date timestamp;

    @Column(name = "notes", nullable = false)
    private String notes;

    @Enumerated(EnumType.STRING)
    private ActivityType activityType;
}