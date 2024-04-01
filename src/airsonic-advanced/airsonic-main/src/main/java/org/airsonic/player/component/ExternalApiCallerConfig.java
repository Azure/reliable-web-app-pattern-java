package org.airsonic.player.component;

import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

@Configuration
public class ExternalApiCallerConfig {
    private static final String VERSION_URL = "https://api.github.com/repos/airsonic-advanced/airsonic-advanced/releases";

    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplateBuilder()
                .rootUri(VERSION_URL)
                .build();
    }
}
