package com.contoso.cams;

import com.contoso.cams.model.Account;
import com.contoso.cams.model.AccountRepository;
import com.contoso.cams.model.Customer;
import com.contoso.cams.model.ServicePlan;
import com.contoso.cams.model.ServicePlanRepository;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import nz.net.ultraq.thymeleaf.layoutdialect.LayoutDialect;

import java.util.Collections;
import java.util.stream.Stream;

@SpringBootApplication
public class CamsApplication {
	public static void main(String[] args) {
		SpringApplication.run(CamsApplication.class, args);
	}

	@Bean
	public LayoutDialect layoutDialect() {
		return new LayoutDialect();
	}

    @ControllerAdvice
    public class ExceptionHandlerControllerAdvice extends ResponseEntityExceptionHandler {
        private static final Logger log = LoggerFactory.getLogger(ExceptionHandlerControllerAdvice.class);

        @ExceptionHandler(AccessDeniedException.class)
        public ProblemDetail exceptionHandler(Exception ex) {
            log.error("Access Denied error", ex);
            ProblemDetail pd = ProblemDetail.forStatusAndDetail(HttpStatus.FORBIDDEN, "You do not have permission to access this resource.");
            return pd;
        }
    }


	// TODO: This is only during development. Remove this before production.
	@Bean
	CommandLineRunner init(AccountRepository accountRepository, ServicePlanRepository servicePlanRepository) {
		return args -> {
			populateAccountDatabase(accountRepository, servicePlanRepository);
		};
	}

	private void populateAccountDatabase(AccountRepository accountRepository, ServicePlanRepository servicePlanRepository) {
		accountRepository.deleteAll();

		Customer customer1 = new Customer("Susan", "Doe", "sd@aol.com", "444-444-4444");
		ServicePlan servicePlan1 = servicePlanRepository.findById(1L).get();
		Account account1 = new Account("123 East St", "Boston", customer1, servicePlan1, true, Collections.emptyList());

		Customer customer2 = new Customer("John", "Doe", "jd@aol.com", "555-555-5555");
		ServicePlan servicePlan2 = servicePlanRepository.findById(2L).get();
		Account account2 = new Account("456 Main St", "Seattle", customer2, servicePlan2, true, Collections.emptyList());

		accountRepository.saveAll(Stream.of(account1, account2).toList());
	}
}
