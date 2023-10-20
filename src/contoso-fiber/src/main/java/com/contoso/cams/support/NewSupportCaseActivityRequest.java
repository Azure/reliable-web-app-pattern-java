package com.contoso.cams.support;

import com.contoso.cams.model.ActivityType;

public record NewSupportCaseActivityRequest(Long caseId, String notes, ActivityType activityType) {
}
