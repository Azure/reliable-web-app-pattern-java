package org.airsonic.player.security;

import com.azure.spring.cloud.autoconfigure.aad.AadWebSecurityConfigurerAdapter;
import com.google.common.collect.ImmutableMap;
import com.google.common.collect.ImmutableSet;
import com.google.common.collect.Sets;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableGlobalMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.crypto.argon2.Argon2PasswordEncoder;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.crypto.password.Pbkdf2PasswordEncoder;
import org.springframework.security.crypto.scrypt.SCryptPasswordEncoder;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@EnableWebSecurity
@EnableGlobalMethodSecurity(securedEnabled = true, prePostEnabled = true)
public class GlobalSecurityConfig {

    @Autowired
    private AADAddAuthorizedUsersFilter aadAddAuthorizedUsersFilter;

    private static final Logger LOG = LoggerFactory.getLogger(GlobalSecurityConfig.class);

    static final String FAILURE_URL = "/login?error";

    private static final String SALT_TOKEN_MECHANISM_SPECIALIZATION = "salttoken";

    @SuppressWarnings("deprecation")
    public static final Map<String, PasswordEncoder> ENCODERS = new HashMap<>(ImmutableMap
            .<String, PasswordEncoder>builderWithExpectedSize(19)
            .put("bcrypt", new BCryptPasswordEncoder())
            .put("ldap", new org.springframework.security.crypto.password.LdapShaPasswordEncoder())
            .put("MD4", new org.springframework.security.crypto.password.Md4PasswordEncoder())
            .put("MD5", new org.springframework.security.crypto.password.MessageDigestPasswordEncoder("MD5"))
            .put("pbkdf2", new Pbkdf2PasswordEncoder())
            .put("scrypt", new SCryptPasswordEncoder())
            .put("SHA-1", new org.springframework.security.crypto.password.MessageDigestPasswordEncoder("SHA-1"))
            .put("SHA-256", new org.springframework.security.crypto.password.MessageDigestPasswordEncoder("SHA-256"))
            .put("sha256", new org.springframework.security.crypto.password.StandardPasswordEncoder())
            .put("argon2", new Argon2PasswordEncoder())

            // base decodable encoders
            .put("noop", new PasswordEncoderDecoderWrapper(org.springframework.security.crypto.password.NoOpPasswordEncoder.getInstance(), p -> p))
            .put("hex", HexPasswordEncoder.getInstance())
            .put("encrypted-AES-GCM", new AesGcmPasswordEncoder()) // placeholder (real instance created below)

            // base decodable encoders that rely on salt+token being passed in (not stored in db with this type)
            .put("noop" + SALT_TOKEN_MECHANISM_SPECIALIZATION, new SaltedTokenPasswordEncoder(p -> p))
            .put("hex" + SALT_TOKEN_MECHANISM_SPECIALIZATION, new SaltedTokenPasswordEncoder(HexPasswordEncoder.getInstance()))
            .put("encrypted-AES-GCM" + SALT_TOKEN_MECHANISM_SPECIALIZATION, new SaltedTokenPasswordEncoder(new AesGcmPasswordEncoder())) // placeholder (real instance created below)

            // TODO: legacy marked base encoders, to be upgraded to one-way formats at breaking version change
            .put("legacynoop", new PasswordEncoderDecoderWrapper(org.springframework.security.crypto.password.NoOpPasswordEncoder.getInstance(), p -> p))
            .put("legacyhex", HexPasswordEncoder.getInstance())

            .put("legacynoop" + SALT_TOKEN_MECHANISM_SPECIALIZATION, new SaltedTokenPasswordEncoder(p -> p))
            .put("legacyhex" + SALT_TOKEN_MECHANISM_SPECIALIZATION, new SaltedTokenPasswordEncoder(HexPasswordEncoder.getInstance()))
            .build());

    public static final Set<String> OPENTEXT_ENCODERS = ImmutableSet.of("noop", "hex", "legacynoop", "legacyhex");
    public static final Set<String> DECODABLE_ENCODERS = ImmutableSet.<String>builder().addAll(OPENTEXT_ENCODERS).add("encrypted-AES-GCM").build();
    public static final Set<String> NONLEGACY_ENCODERS = ENCODERS.keySet().stream()
            .filter(e -> !StringUtils.containsAny(e, "legacy", SALT_TOKEN_MECHANISM_SPECIALIZATION))
            .collect(Collectors.toSet());
    public static final Set<String> NONLEGACY_DECODABLE_ENCODERS = Sets.intersection(DECODABLE_ENCODERS, NONLEGACY_ENCODERS);
    public static final Set<String> NONLEGACY_NONDECODABLE_ENCODERS = Sets.difference(NONLEGACY_ENCODERS, DECODABLE_ENCODERS);

    @Autowired
    private CsrfSecurityRequestMatcher csrfSecurityRequestMatcher;

    @Configuration
    public class WebSecurityConfiguration extends AadWebSecurityConfigurerAdapter {

        @Override
        protected void configure(HttpSecurity http) throws Exception {
            // use required configuration from AADWebSecurityAdapter.configure:
            super.configure(http);
            // add custom configuration:

            http
                    .cors()
                    .and()
                    .csrf()
                    .requireCsrfProtectionMatcher(csrfSecurityRequestMatcher)
                    .and()
                    .headers()
                    .frameOptions()
                    .sameOrigin()
                    .and().authorizeRequests()
                    .antMatchers("/recover*", "/accessDenied*", "/style/**", "/icons/**", "/flash/**", "/script/**", "/error")
                    .permitAll()
                    .antMatchers("/personalSettings*",
                            "/playerSettings*", "/shareSettings*", "/credentialsSettings*")
                    .hasAnyAuthority("APPROLE_Admin", "APPROLE_Creator", "APPROLE_User")
                    .antMatchers("/generalSettings*", "/advancedSettings*", "/userSettings*",
                            "/musicFolderSettings*", "/databaseSettings*", "/transcodeSettings*", "/rest/startScan*")
                    .hasAnyAuthority("APPROLE_Admin")
                    .antMatchers("/deletePlaylist*", "/savePlaylist*")
                    .hasAnyAuthority("APPROLE_Admin", "APPROLE_Creator")
                    .antMatchers("/download*")
                    .hasAnyAuthority("APPROLE_Admin", "APPROLE_Creator", "APPROLE_User")
                    .antMatchers("/upload*")
                    .hasAnyAuthority("APPROLE_Admin", "APPROLE_Creator")
                    .antMatchers("/createShare*")
                    .hasAnyAuthority("APPROLE_Admin", "APPROLE_Creator")
                    .antMatchers("/changeCoverArt*", "/editTags*")
                    .hasAnyAuthority("APPROLE_Admin", "APPROLE_Creator")
                    .antMatchers("/setMusicFileInfo*")
                    .hasAnyAuthority("APPROLE_Admin", "APPROLE_Creator")
                    .antMatchers("/podcastReceiverAdmin*")
                    .hasAnyAuthority("APPROLE_Admin", "APPROLE_Creator")
                    .antMatchers("/**")
                    .hasAnyAuthority("APPROLE_Admin", "APPROLE_Creator", "APPROLE_User")
                    .anyRequest().authenticated()
                    .and()
                    .addFilterBefore(aadAddAuthorizedUsersFilter, UsernamePasswordAuthenticationFilter.class)
                    .logout(logout -> logout
                            .deleteCookies("JSESSIONID", "XSRF-TOKEN")
                            .clearAuthentication(true)
                            .invalidateHttpSession(true)
                            .logoutSuccessUrl("/index"))
                    ;
        }
    }

    @Bean
    CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(Collections.singletonList("*"));
        configuration.setAllowedMethods(Collections.singletonList("*"));
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/rest/**", configuration);
        source.registerCorsConfiguration("/stream/**", configuration);
        source.registerCorsConfiguration("/hls**", configuration);
        source.registerCorsConfiguration("/captions**", configuration);
        source.registerCorsConfiguration("/ext/stream/**", configuration);
        source.registerCorsConfiguration("/ext/hls**", configuration);
        source.registerCorsConfiguration("/ext/captions**", configuration);
        return source;
    }
}
