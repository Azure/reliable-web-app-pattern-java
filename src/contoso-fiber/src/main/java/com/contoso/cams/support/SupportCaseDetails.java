package com.contoso.cams.support;

import java.util.Date;
import java.util.List;

import com.contoso.cams.model.SupportCaseQueue;

import lombok.Data;

@Data
public class SupportCaseDetails {

    private Long caseId;
    private String description;
    private SupportCaseQueue status;
    private Date creationDate;

    private Long accountId;
    private String address;
    private String city;

    private String customerFirstName;
    private String customerLastName;
    private String customerEmailAddress;
    private String customerPhoneNumber;

    private List<SupportCaseActivityDto> activities;

    private String assignee;
}
