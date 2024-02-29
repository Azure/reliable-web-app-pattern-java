package com.contoso.cams.serviceplan;

import java.util.List;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;

import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Controller
@AllArgsConstructor
@Slf4j
@RequestMapping(value = "/plans")
public class ServicePlanController {

    private final ServicePlanService planService;

    private static final String SERVICE_PLAN = "servicePlan";

    @GetMapping("/list")
    @PreAuthorize("hasAnyAuthority('APPROLE_AccountManager')")
    @CircuitBreaker(name = SERVICE_PLAN)
    @Retry(name = SERVICE_PLAN)
    public String listServicePlans(Model model) {
        List<ServicePlanDto> servicePlans = planService.getServicePlans();
        model.addAttribute("servicePlans", servicePlans);
        return "pages/plans/list";
    }

    @GetMapping("/details")
    @PreAuthorize("hasAnyAuthority('APPROLE_AccountManager')")
    public String getServicePlan(Model model, @RequestParam("id") Long id) {

        try {
            ServicePlanDto servicePlan = planService.getServicePlan(id);
            model.addAttribute("servicePlan", servicePlan);
            return "pages/plans/detail";
        } catch (IllegalArgumentException ex) {
            log.error("Error getting service plan details", ex);
            return "pages/plans/notfound";
        }
    }

    @PostMapping("/update")
    @PreAuthorize("hasAnyAuthority('APPROLE_AccountManager')")
    public String updateServicePlan(Model model, @ModelAttribute("servicePlan") ServicePlanDto servicePlan) {
        log.info("Updating service plan: {}", servicePlan);

        try {
            planService.updateServicePlan(servicePlan);
            return "redirect:/plans/list";
        } catch (IllegalArgumentException ex) {
            log.error("Error updating service plan", ex);
            return "pages/plans/notfound";
        }
    }

}
