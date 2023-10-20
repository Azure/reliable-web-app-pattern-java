package com.contoso.cams.serviceplan;

public record ServicePlanDto(Long id, String name, String description, Integer installationPrice, Integer monthlyPrice, Boolean isDefault) {
}
