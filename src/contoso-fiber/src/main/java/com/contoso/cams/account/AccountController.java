package com.contoso.cams.account;

import java.util.List;
import com.contoso.cams.model.Account;
import com.contoso.cams.model.ServicePlan;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.domain.Sort.Direction;
import org.springframework.data.domain.Sort.Order;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;

import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
@AllArgsConstructor
@RequestMapping("/accounts")
public class AccountController {
    private static final Logger log = LoggerFactory.getLogger(AccountController.class);

    private final AccountService accountService;

    @GetMapping("/list")
    @PreAuthorize("hasAnyAuthority('APPROLE_AccountManager', 'APPROLE_L1Support', 'APPROLE_L2Support', 'APPROLE_FieldService')")
    public String getAccount(Model model, @RequestParam(required = false) String keyword,
                             @RequestParam(defaultValue = "1") int page,
                             @RequestParam(defaultValue = "6") int size,
                             @RequestParam(defaultValue = "id,asc") String[] sort) {

        String sortField = sort[0];
        String sortDirection = sort[1];

        Direction direction = sortDirection.equals("desc") ? Direction.DESC : Sort.Direction.ASC;
        Order order = new Order(direction, sortField);

        Pageable pageable = PageRequest.of(page - 1, size, Sort.by(order));

        if (keyword != null) {
            model.addAttribute("keyword", keyword);
        }

        //Page<Account> accounts = (keyword == null) ? accountRepository.findAll(pageable) : accountRepository.findByKeyword(keyword, pageable);
        Page<Account> accounts = accountService.findAll(pageable);
        model.addAttribute("accounts", accounts.getContent());
        model.addAttribute("currentPage", accounts.getNumber() + 1);
        model.addAttribute("totalItems", accounts.getTotalElements());
        model.addAttribute("totalPages", accounts.getTotalPages());
        model.addAttribute("pageSize", size);
        model.addAttribute("sortField", sortField);
        model.addAttribute("sortDirection", sortDirection);
        model.addAttribute("reverseSortDirection", sortDirection.equals("asc") ? "desc" : "asc");
        return "pages/account/list";
    }

    @GetMapping("/new")
    @PreAuthorize("hasAnyAuthority('APPROLE_AccountManager')")
    public String newAccount(Model model) {
        if (model.getAttribute("account") == null) {
            List<ServicePlan> servicePlans = accountService.findAllServicePlans();
            ServicePlan defaultServicePlan = servicePlans.stream().filter(sp -> sp.getIsDefault() == true).findFirst().orElse(null);
            NewAccountRequest accountFormData = new NewAccountRequest();
            accountFormData.setSelectedServicePlanId(defaultServicePlan.getId());
            model.addAttribute("account", accountFormData);
            model.addAttribute("servicePlans", servicePlans);
        }
        model.addAttribute("servicePlans", accountService.findAllServicePlans());
        return "pages/account/new";
    }

    @PostMapping("/new")
    @PreAuthorize("hasAnyAuthority('APPROLE_AccountManager')")
    public String newAccount(Model model, @Valid @ModelAttribute("account") NewAccountRequest newAccountRequest, BindingResult result) {
        log.info("submitNewCustomer: {}", newAccountRequest);

        try {
            if (result.hasErrors()) {
                String errorMessage = result.getAllErrors().get(0).getDefaultMessage();
                log.error("Validation errors while submitting new account: {}", errorMessage);
                throw new IllegalArgumentException("Validation errors while submitting new account - " + errorMessage);
            }

            Account newAccount = accountService.createAccount(newAccountRequest);
            return "redirect:/accounts/details?id=" + newAccount.getId();
        } catch (IllegalArgumentException ex) {
            model.addAttribute("message", ex.getMessage());
            model.addAttribute("servicePlans", accountService.findAllServicePlans());
            return "pages/account/new";
        }
    }

    @GetMapping("/details")
    @PreAuthorize("hasAnyAuthority('APPROLE_AccountManager', 'APPROLE_L1Support', 'APPROLE_L2Support', 'APPROLE_FieldService')")
    public String getAccountDetails(Model model, @RequestParam("id") Long id) {
        log.info("getAccountDetails: {}", id);

        try {
            AccountDetail accountDetail = accountService.getAccountDetails(id);
            model.addAttribute("account", accountDetail);
            model.addAttribute("servicePlans", accountService.findAllServicePlans());
            return "pages/account/detail";
        } catch (IllegalArgumentException ex) {
            log.error("Account ID {} does not exist", id);
            return "pages/account/error";
        }
    }

    @PostMapping("/update")
    @PreAuthorize("hasAnyAuthority('APPROLE_AccountManager')")
    public String updateAccount(Model model, @Valid @ModelAttribute("account") AccountDetail account, BindingResult result) {
        log.info("updateAccount: {}", account);

        try {
            if (result.hasErrors()) {
                String errorMessage = result.getAllErrors().get(0).getDefaultMessage();
                log.error("Validation errors while submitting new account: {}", errorMessage);
                throw new IllegalArgumentException("Validation errors while submitting new account - " + errorMessage);
            }

            Account updatedAccount = accountService.updateAccount(account);
            return "redirect:/accounts/details?id=" + updatedAccount.getId();
        } catch (IllegalArgumentException ex) {
            model.addAttribute("message", ex.getMessage());
            model.addAttribute("servicePlans", accountService.findAllServicePlans());
            return "pages/account/detail";
        }
    }

    @PostMapping("/{id}/deactivate")
    @PreAuthorize("hasAnyAuthority('APPROLE_AccountManager')")
    public String deactivateAccount(Model model, @PathVariable("id") Long id) {
        log.info("deactivateAccount: {}", id);

        try {
            Account deactivatedAccount = accountService.setActive(id, false);
            return "redirect:/accounts/details?id=" + deactivatedAccount.getId();
        } catch (IllegalArgumentException ex) {
            model.addAttribute("message", ex.getMessage());
            return "redirect:/account/list";
        }
    }

    @PostMapping("/{id}/activate")
    @PreAuthorize("hasAnyAuthority('APPROLE_AccountManager')")
    public String activateAccount(Model model, @PathVariable("id") Long id) {
        log.info("activateAccount: {}", id);

        try {
            Account activatedAccount = accountService.setActive(id, true);
            return "redirect:/accounts/details?id=" + activatedAccount.getId();
        } catch (IllegalArgumentException ex) {
            model.addAttribute("message", ex.getMessage());
            return "redirect:/account/list";
        }
    }
}
