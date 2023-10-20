package com.contoso.cams.support;

import lombok.Data;

@Data
public class NewSupportCaseRequest {

    private Long accountId;

    private String customerFirstName;

    private String customerLastName;

    private String customerEmailAddress;

    private String customerPhoneNumber;

    private String description;
}
