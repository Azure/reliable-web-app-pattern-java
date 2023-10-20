package com.contoso.cams;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.when;

import java.util.Collections;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.contoso.cams.account.AccountService;
import com.contoso.cams.account.NewAccountRequest;
import com.contoso.cams.model.Account;
import com.contoso.cams.model.AccountRepository;
import com.contoso.cams.model.Customer;
import com.contoso.cams.model.ServicePlan;
import com.contoso.cams.model.ServicePlanRepository;

@ExtendWith(MockitoExtension.class)
public class AccountServiceUnitTests {

    @Mock
    private AccountRepository accountRepository;

    @Mock
    private ServicePlanRepository servicePlanRepository;

    @InjectMocks
    private AccountService accountService;

    private Customer customer;
    private Account account;
    private ServicePlan basicServicePlan;


    @BeforeEach
    public void setup() {
        basicServicePlan = new ServicePlan("Basic", "Basic", 100, 10, true);
        basicServicePlan.setId(101L);
        customer = new Customer("John", "Doe", "jd@contoso.com", "555-555-5555");
        customer.setId(201L);
        account = new Account("123 Main St", "Redmond", customer, basicServicePlan, true, Collections.emptyList());
        account.setId(301L);
    }
    
    @DisplayName("Create account with null request throws IllegalArgumentException")
    @Test
    public void createAccountWithNullRequestThrowsIllegalArgumentException() {
    
        // Act & Assert
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> {
            accountService.createAccount(null);
        });

        assertThat(ex.getMessage()).isEqualTo("New account request can not be null");
    }

    @DisplayName("Create account fails if active account exists for the address")
    @Test
    public void createAccountFailsIfActiveAccountExistsForTheAddress() {
        // Arrange
        NewAccountRequest newAccountRequest = new NewAccountRequest();
        newAccountRequest.setAddress(account.getAddress());
        newAccountRequest.setCity(account.getCity());

        when(accountRepository.findByAddressLikeIgnoreCaseAndCityLikeIgnoreCase(account.getAddress(), account.getCity()))
                .thenReturn(Optional.of(account));

        // Act
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> {
            accountService.createAccount(newAccountRequest);
        });

        // Assert
        assertThat(ex.getMessage()).isEqualTo("Found previous active account. Account ID: " + account.getId());
    }

    @DisplayName("Create account fails if account exists for the customer based on email address")
    @Test
    public void createAccountFailsIfAccountExistsForTheCustomerBasedOnEmailAddress() {
        // Arrange
        NewAccountRequest newAccountRequest = new NewAccountRequest();
        account.setActive(false);
        newAccountRequest.setAddress(account.getAddress());
        newAccountRequest.setCity(account.getCity());
        newAccountRequest.setCustomerFirstName("Susan");
        newAccountRequest.setCustomerLastName("Smith");
        newAccountRequest.setCustomerEmail(customer.getEmailAddress());
        newAccountRequest.setCustomerPhoneNumber("555-555-5555");
        newAccountRequest.setSelectedServicePlanId(1L);

        when(accountRepository.findByAddressLikeIgnoreCaseAndCityLikeIgnoreCase(account.getAddress(), account.getCity()))
                .thenReturn(Optional.of(account));

        when(accountRepository.findByIdAndCustomerEmailAddress(account.getId(), account.getCustomer().getEmailAddress()))
                .thenReturn(Optional.of(account));

        // Act
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> {
            accountService.createAccount(newAccountRequest);
        });

        // Assert
        assertThat(ex.getMessage()).isEqualTo("Found previous account with same customer email. Account ID: " + account.getId() + ". Please activate that account");
    }

    @DisplayName("Create account fails if account exists for the customer based on phone number")
    @Test
    public void createAccountFailsIfAccountExistsForTheCustomerBasedOnPhoneNumber() {
        // Arrange
        NewAccountRequest newAccountRequest = new NewAccountRequest();
        account.setActive(false);
        newAccountRequest.setAddress(account.getAddress());
        newAccountRequest.setCity(account.getCity());
        newAccountRequest.setCustomerFirstName("Susan");
        newAccountRequest.setCustomerLastName("Smith");
        newAccountRequest.setCustomerEmail(customer.getEmailAddress());
        newAccountRequest.setCustomerPhoneNumber("555-555-5555");
        newAccountRequest.setSelectedServicePlanId(1L);

        when(accountRepository.findByAddressLikeIgnoreCaseAndCityLikeIgnoreCase(account.getAddress(), account.getCity()))
                .thenReturn(Optional.of(account));

        when(accountRepository.findByIdAndCustomerPhoneNumber(account.getId(), account.getCustomer().getPhoneNumber()))
                .thenReturn(Optional.of(account));
        
        // Act
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> {
            accountService.createAccount(newAccountRequest);
        });

        // Assert
        assertThat(ex.getMessage()).isEqualTo("Found previous account with same customer phone number. Account ID: " + account.getId() + ". Please activate that account");
    }
}
