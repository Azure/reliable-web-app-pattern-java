package com.contoso.cams.security;

import java.util.Optional;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.client.authentication.OAuth2AuthenticationToken;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.stereotype.Service;

@Service
public class UserInfoService {

    public UserInfo getUserInfo() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        UserInfo user = Optional.of(authentication)
				.map(auth -> (OAuth2AuthenticationToken) auth)
				.map(OAuth2AuthenticationToken::getPrincipal)
				.map(OidcUser -> (OidcUser) OidcUser)
                .map(principal -> new UserInfo(principal.getFullName(), principal.getClaimAsString("oid")))
                .orElseThrow(() -> new RuntimeException("Unable to get user details"));

        return user;
    }
}
