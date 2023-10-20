package com.contoso.cams.support;

import java.util.Date;

import com.contoso.cams.model.ActivityType;

import lombok.Data;

@Data
public class SupportCaseActivityDto {
    private Long id;
    private Date timestamp;
    private String notes;
    private ActivityType activityType;

    // TODO: Add assignee
    private String assignee = "1234";
}
