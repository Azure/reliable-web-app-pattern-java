package com.contoso.cams.model;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface AccountRepository extends JpaRepository<Account, Long> {

    Optional<Account> findByAddressLikeIgnoreCaseAndCityLikeIgnoreCase(String address, String city);

    Optional<Account> findByIdAndCustomerEmailAddress(Long accountId, String emailAddress);

    Optional<Account> findByIdAndCustomerPhoneNumber(Long accountId, String phoneNumber);
}
