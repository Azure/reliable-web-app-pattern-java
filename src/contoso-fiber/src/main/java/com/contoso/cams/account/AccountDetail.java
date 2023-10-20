package com.contoso.cams.account;

import java.util.List;

import com.contoso.cams.constraint.ValidCustomerName;
import com.contoso.cams.constraint.ValidPhoneNumber;

import jakarta.validation.constraints.*;
import lombok.Data;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@Data
public class AccountDetail {
    @NotNull(message = "Account Id is mandatory")
    private Long accountId;

    @NotNull(message = "Customer Id is mandatory")
    private Long customerId;

    @NotBlank(message = "Address is mandatory")
    private String address;

    @NotBlank(message = "City is mandatory")
    private String city;

    @ValidCustomerName(message = "Customer first name must be between 2 and 64 characters")
    private String customerFirstName;

    @ValidCustomerName(message = "Customer last name must be between 2 and 64 characters")
    private String customerLastName;

    @NotBlank(message = "Email address is mandatory")
    @Email(message = "Email address is not valid")
    private String customerEmail;

    @ValidPhoneNumber
    private String customerPhoneNumber;

    @NotNull(message = "Selected service plan is mandatory")
    private Long selectedServicePlanId;

    private boolean active;

    List<SupportCaseDetail> supportCases;
}
