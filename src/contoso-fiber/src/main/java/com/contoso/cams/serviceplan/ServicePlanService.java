package com.contoso.cams.serviceplan;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.contoso.cams.model.ServicePlan;
import com.contoso.cams.model.ServicePlanRepository;

import lombok.AllArgsConstructor;

@Service
@AllArgsConstructor
public class ServicePlanService {

    private final ServicePlanRepository planRepository;

    public List<ServicePlanDto> getServicePlans() {
        List<ServicePlan> servicePlans = planRepository.findAll();
        List<ServicePlanDto> servicePlanDtos = servicePlans.stream()
            .map(servicePlan -> new ServicePlanDto(
                servicePlan.getId(),
                servicePlan.getName(),
                servicePlan.getDescription(),
                servicePlan.getInstallationPrice(),
                servicePlan.getMonthlyPrice(),
                servicePlan.getIsDefault()))
            .collect(Collectors.toList());

        return servicePlanDtos;
    }

    public ServicePlanDto getServicePlan(Long id) {
        Optional<ServicePlan> servicePlan = planRepository.findById(id);

        ServicePlanDto servicePlanDto = servicePlan.map(s -> new ServicePlanDto(
            s.getId(),
            s.getName(),
            s.getDescription(),
            s.getInstallationPrice(),
            s.getMonthlyPrice(),
            s.getIsDefault()))
            .orElseThrow(() -> new IllegalArgumentException("Service plan not found. ID: " + id));

        return servicePlanDto;
    }

    public void updateServicePlan(ServicePlanDto servicePlan) {
        Optional<ServicePlan> existingServicePlan = planRepository.findById(servicePlan.id());
        if (existingServicePlan.isEmpty()) {
            throw new IllegalArgumentException("Service plan not found. ID: " + servicePlan.id());
        }

        ServicePlan updatedServicePlan = existingServicePlan.get();
        updatedServicePlan.setDescription(servicePlan.description());
        planRepository.save(updatedServicePlan);
    }

}
