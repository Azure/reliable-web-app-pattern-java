package com.contoso.cams.account;

import java.util.List;
import java.util.Optional;
import com.contoso.cams.model.Account;
import com.contoso.cams.model.AccountRepository;
import com.contoso.cams.model.Customer;
import com.contoso.cams.model.CustomerRepository;
import com.contoso.cams.model.ServicePlan;
import com.contoso.cams.model.ServicePlanRepository;
import com.contoso.cams.model.SupportCase;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cache.annotation.CacheConfig;
import org.springframework.cache.annotation.CachePut;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

@Service
@CacheConfig(cacheNames={"accounts"})
public class AccountService {
    private static final Logger log = LoggerFactory.getLogger(AccountService.class);

    private final AccountRepository accountRepository;
    private final ServicePlanRepository servicePlanRepository;
    private final CustomerRepository customerRepository;

    public AccountService(AccountRepository accountRepository,
                          ServicePlanRepository servicePlanRepository,
                          CustomerRepository customerRepository) {
        this.accountRepository = accountRepository;
        this.servicePlanRepository = servicePlanRepository;
        this.customerRepository = customerRepository;
    }

    public Page<Account> findAll(Pageable pageable) {
        Page<Account> accounts = accountRepository.findAll(pageable);
        return accounts;
    }

    public Account createAccount(NewAccountRequest newAccountRequest) throws IllegalArgumentException {
        if (newAccountRequest == null) {
            throw new IllegalArgumentException("New account request can not be null");
        }

        validateAccountCanBeCreated(newAccountRequest);

        ServicePlan servicePlan = servicePlanRepository.findById(newAccountRequest.getSelectedServicePlanId()).orElseThrow(() -> new IllegalArgumentException("Invalid service plan ID"));

        Customer customer = new Customer();
        customer.setFirstName(newAccountRequest.getCustomerFirstName());
        customer.setLastName(newAccountRequest.getCustomerLastName());
        customer.setEmailAddress(newAccountRequest.getCustomerEmail());
        customer.setPhoneNumber(newAccountRequest.getCustomerPhoneNumber());

        Account account = new Account();
        account.setCustomer(customer);
        account.setAddress(newAccountRequest.getAddress());
        account.setCity(newAccountRequest.getCity());
        // All new accounts are active accounts
        account.setActive(true);
        account.setServicePlan(servicePlan);

        return accountRepository.save(account);
    }

    private void validateAccountCanBeCreated(NewAccountRequest account) throws IllegalArgumentException {
        log.debug("Validating that account can be created");

        Optional<Account> existingAccount = accountRepository.findByAddressLikeIgnoreCaseAndCityLikeIgnoreCase(account.getAddress(), account.getCity());

        // If there is no existing account, then we can create the new account
        if (existingAccount.isEmpty()) {
            return;
        }

        ensureExistingAccountIsNotActive(existingAccount.get());
        ensureCustomerEmailIsUnique(existingAccount.get().getId(), account.getCustomerEmail());
        ensureCustomerPhoneNumberIsUnique(existingAccount.get().getId(), account.getCustomerPhoneNumber());
    }

    private void ensureExistingAccountIsNotActive(Account account) {
        if (account.isActive()) {
            throw new IllegalArgumentException("Found previous active account. Account ID: " + account.getId());
        }
    }

    private void ensureCustomerEmailIsUnique(Long accountId, String customerEmail) {
        // verify that the customer email address is not null or blank
        if (customerEmail == null || customerEmail.isBlank()) {
            throw new IllegalArgumentException("Customer email address is mandatory");
        }

        Optional<Account> existingAccount = accountRepository.findByIdAndCustomerEmailAddress(accountId, customerEmail);
        if (existingAccount.isPresent()) {
            throw new IllegalArgumentException("Found previous account with same customer email. Account ID: " + existingAccount.get().getId() + ". Please activate that account");
        }
    }

    private void ensureCustomerPhoneNumberIsUnique(Long accountId, String customerPhoneNumber) {
        // verify that the customer phone number is not null or blank
        if (customerPhoneNumber == null || customerPhoneNumber.isBlank()) {
            throw new IllegalArgumentException("Customer phone number is mandatory");
        }

        Optional<Account> existingAccount = accountRepository.findByIdAndCustomerPhoneNumber(accountId, customerPhoneNumber);
        if (existingAccount.isPresent()) {
            throw new IllegalArgumentException("Found previous account with same customer phone number. Account ID: " + existingAccount.get().getId() + ". Please activate that account");
        }
    }

    public List<ServicePlan> findAllServicePlans() {
        return servicePlanRepository.findAll();
    }

    @CachePut(value="account-details", key="#accountDetail.accountId")
    public AccountDetail updateAccount(AccountDetail accountDetail) {

        // Update the customer email and phone number
        Optional<Customer> optionalCustomer = customerRepository.findById(accountDetail.getCustomerId());
        if (optionalCustomer.isEmpty()) {
            throw new IllegalArgumentException("Customer ID " + accountDetail.getCustomerId() + " does not exist");
        }
        Customer customer = optionalCustomer.get();
        customer.setEmailAddress(accountDetail.getCustomerEmail());
        customer.setPhoneNumber(accountDetail.getCustomerPhoneNumber());
        customerRepository.save(customer);

        // Update the service plan
        Optional<ServicePlan> optionalServicePlan = servicePlanRepository.findById(accountDetail.getSelectedServicePlanId());
        if (optionalServicePlan.isEmpty()) {
            throw new IllegalArgumentException("Service plan ID " + accountDetail.getSelectedServicePlanId() + " does not exist");
        }
        ServicePlan servicePlan = optionalServicePlan.get();
        Optional<Account> optionalAccount = accountRepository.findById(accountDetail.getAccountId());
        if (optionalAccount.isEmpty()) {
            throw new IllegalArgumentException("Account ID " + accountDetail.getAccountId() + " does not exist");
        }
        Account account = optionalAccount.get();
        account.setServicePlan(servicePlan);

        return mapToAccountDetail(accountRepository.save(account));
    }

    @CachePut(value="account-details", key="#id")
    public AccountDetail setActive(Long id, boolean isActive) {
        Optional<Account> optionalAccount = accountRepository.findById(id);
        if (optionalAccount.isEmpty()) {
            throw new IllegalArgumentException("Account ID " + id + " does not exist");
        }

        Account account = optionalAccount.get();
        account.setActive(isActive);
        return mapToAccountDetail(accountRepository.save(account));
    }

    @Cacheable(value="account-details", key="#id")
    public AccountDetail getAccountDetail(Long id) {
        Optional<Account> optionalAccount = accountRepository.findById(id);
        if (optionalAccount.isEmpty()) {
            throw new IllegalArgumentException("Account ID " + id + " does not exist");
        }

        Account account = optionalAccount.get();
        AccountDetail accountDetail = mapToAccountDetail(account);

        return accountDetail;
    }

    private AccountDetail mapToAccountDetail(Account account) {
        AccountDetail accountDetail = new AccountDetail();
        accountDetail.setAccountId(account.getId());
        accountDetail.setAddress(account.getAddress());
        accountDetail.setCity(account.getCity());
        accountDetail.setCustomerId(account.getCustomer().getId());
        accountDetail.setCustomerEmail(account.getCustomer().getEmailAddress());
        accountDetail.setCustomerFirstName(account.getCustomer().getFirstName());
        accountDetail.setCustomerLastName(account.getCustomer().getLastName());
        accountDetail.setCustomerPhoneNumber(account.getCustomer().getPhoneNumber());
        accountDetail.setSelectedServicePlanId(account.getServicePlan().getId());
        accountDetail.setActive(account.isActive());

        List<SupportCase> supportCases = account.getSupportCases();
        List<SupportCaseDetail> supportCaseDetails = supportCases.stream()
                    .map(s -> new SupportCaseDetail(s.getId(), s.getDescription(), s.getQueue().toString(), s.getTimestamp().toString(), s.getAssignedTo()))
                    .collect(java.util.stream.Collectors.toList());
        accountDetail.setSupportCases(supportCaseDetails);
        return accountDetail;
    }
}
