package com.contoso.cams.security;

import org.springframework.boot.actuate.autoconfigure.security.servlet.EndpointRequest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;

import com.azure.spring.cloud.autoconfigure.implementation.aad.security.AadWebApplicationHttpSecurityConfigurer;

@Configuration(proxyBeanMethods = false)
@EnableWebSecurity
@EnableMethodSecurity
public class AadOAuth2LoginSecurityConfig {

    /**
     * Add configuration logic as needed.
     */
    @Bean
    SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.apply(AadWebApplicationHttpSecurityConfigurer.aadWebApplication())
            .and()
                .authorizeHttpRequests()
            .requestMatchers(EndpointRequest.to("health")).permitAll()
            .anyRequest().authenticated()
            .and()
                .logout(logout -> logout
                            .deleteCookies("JSESSIONID", "XSRF-TOKEN")
                            .clearAuthentication(true)
                            .invalidateHttpSession(true));
        // Do some custom configuration.
        return http.build();
    }
}
