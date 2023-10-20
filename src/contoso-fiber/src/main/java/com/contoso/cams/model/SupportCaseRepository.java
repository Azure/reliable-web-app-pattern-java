package com.contoso.cams.model;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface SupportCaseRepository extends JpaRepository<SupportCase, Long>{

    List<SupportCase> findAllByAssignedTo(String employeeId);
    List<SupportCase> findAllByQueue(SupportCaseQueue queue);

}
