package com.contoso.cams.account;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class SupportCaseDetail {
    private Long supportCaseId;
    private String description;
    private String queue;
    private String creationDate;
    private String assignee;
}
