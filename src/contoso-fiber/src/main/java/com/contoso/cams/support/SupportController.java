package com.contoso.cams.support;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import com.contoso.cams.model.SupportCaseQueue;
import com.contoso.cams.security.UserInfo;
import com.contoso.cams.security.UserInfoService;

import lombok.AllArgsConstructor;

@Controller
@AllArgsConstructor
@RequestMapping("/support")
public class SupportController {

    private static final Logger log = LoggerFactory.getLogger(SupportController.class);

    private final SupportCaseService supportCaseService;
    private final UserInfoService userDetailService;

    @GetMapping(value = "/new")
    @PreAuthorize("hasAnyAuthority('APPROLE_L1Support', 'APPROLE_L2Support', 'APPROLE_FieldService')")
    public String newSupportCase(Model model, @RequestParam(value = "account-id") Long accountId) {
        NewSupportCaseRequest newSupportCaseRequest = supportCaseService.generateNewSupportCaseRequest(accountId);
        model.addAttribute("case", newSupportCaseRequest);
        return "pages/support/new";
    }

    @PostMapping(value = "/new")
    @PreAuthorize("hasAnyAuthority('APPROLE_L1Support', 'APPROLE_L2Support', 'APPROLE_FieldService')")
    public String newSupportCase(Model model, @ModelAttribute("case") NewSupportCaseRequest newSupportCaseRequest) {
        log.info("New support case request: {}", newSupportCaseRequest);
        supportCaseService.createSupportCase(newSupportCaseRequest);
        return "redirect:/accounts/details?id=" + newSupportCaseRequest.getAccountId();
    }

    @GetMapping(value = "/details")
    @PreAuthorize("hasAnyAuthority('APPROLE_L1Support', 'APPROLE_L2Support', 'APPROLE_FieldService')")
    public String getSupportCaseDetails(Model model, @RequestParam(value = "id") Long id) {
        SupportCaseDetails supportCaseDetails = supportCaseService.getSupportCaseDetails(id);
        UserInfo userInfo = userDetailService.getUserInfo();
        model.addAttribute("caseDetails", supportCaseDetails);
        model.addAttribute("userInfo", userInfo);
        return "pages/support/details";
    }

    @PostMapping(value = "/newactivity", consumes = MediaType.APPLICATION_FORM_URLENCODED_VALUE)
    @PreAuthorize("hasAnyAuthority('APPROLE_L1Support', 'APPROLE_L2Support', 'APPROLE_FieldService')")
    public String newActivity(Model model, NewSupportCaseActivityRequest newSupportCaseActivityRequest) {
        log.info("New support case activity request: {}", newSupportCaseActivityRequest);
        supportCaseService.createSupportCaseActivity(newSupportCaseActivityRequest);
        return "redirect:/support/details?id=" + newSupportCaseActivityRequest.caseId();
    }

    // Assign support case to a queue
    @PostMapping(value = "{id}/assign/queue/{queue}")
    @PreAuthorize("hasAnyAuthority('APPROLE_L1Support', 'APPROLE_L2Support', 'APPROLE_FieldService')")
    public String assignSupportCaseToQueue(Model model, @PathVariable("id") Long id, @PathVariable("queue") String queue) {
        log.info("Assign support case {} to queue request: {}", id, queue);

        SupportCaseQueue supportCaseQueue = SupportCaseQueue.valueOf(queue.toUpperCase());

        supportCaseService.assignSupportCaseToQueue(id, supportCaseQueue);
        return "redirect:/support/details?id=" + id;
    }

    // Assign support case to the current user
    @PostMapping(value = "{id}/assign/user/me")
    @PreAuthorize("hasAnyAuthority('APPROLE_L1Support', 'APPROLE_L2Support', 'APPROLE_FieldService')")
    public String assignSupportCaseToUser(@AuthenticationPrincipal OidcUser principal, Model model, @PathVariable("id") Long id) {
        log.info("Assign support case {} to user request: {}", id, principal.getFullName());

        UserInfo user = userDetailService.getUserInfo();
        supportCaseService.assignSupportCaseToUser(id, user);
        return "redirect:/support/details?id=" + id;
    }

    @GetMapping(value = "/cases/assignedTo/me")
    @PreAuthorize("hasAnyAuthority('APPROLE_L1Support', 'APPROLE_L2Support', 'APPROLE_FieldService')")
    public String getSupportCasesAssignedToMe(Model model) {
        UserInfo user = userDetailService.getUserInfo();
        List<SupportCaseDetails> supportCases = supportCaseService.getSupportCasesAssignedToUser(user);
        model.addAttribute("supportCases", supportCases);
        return "pages/support/queue";
    }

    @GetMapping(value = "/cases")
    @PreAuthorize("hasAnyAuthority('APPROLE_L1Support', 'APPROLE_L2Support', 'APPROLE_FieldService')")
    public String getAllSupportCases(Model model, @RequestParam(required = false) String queue) {
        List<SupportCaseDetails> supportCases = (queue == null) ?
            supportCaseService.getAllSupportCases() :
            supportCaseService.getSupportCasesByQueue(SupportCaseQueue.valueOf(queue.toUpperCase()));

        model.addAttribute("supportCases", supportCases);
        return "pages/support/queue";
    }
}
