package com.contoso.cams.account;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class SupportCaseDetail {
    private Long supportCaseId;
    private String description;
    private String queue;
    private String creationDate;
    private String assignee;
}
