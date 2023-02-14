/*
 This file is part of Airsonic.

 Airsonic is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Airsonic is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Airsonic.  If not, see <http://www.gnu.org/licenses/>.

 Copyright 2016 (C) Airsonic Authors
 Based upon Subsonic, Copyright 2009 (C) Sindre Mehus
 */
package org.airsonic.player.service;

import com.fasterxml.jackson.core.type.TypeReference;
import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.github.resilience4j.retry.RetryConfig;
import io.github.resilience4j.retry.RetryRegistry;
import io.github.resilience4j.retry.annotation.Retry;
import org.airsonic.player.domain.Version;
import org.airsonic.player.util.Util;
import org.apache.commons.lang3.StringUtils;
import org.apache.http.HttpEntity;
import org.apache.http.client.ResponseHandler;
import org.apache.http.client.config.RequestConfig;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.conn.ConnectTimeoutException;
import org.apache.http.impl.client.AbstractResponseHandler;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.support.PropertiesLoaderUtils;
import org.springframework.stereotype.Service;

import javax.annotation.PostConstruct;

import java.io.*;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Properties;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Provides version-related services, including functionality for determining whether a newer
 * version of Airsonic is available.
 *
 * @author Sindre Mehus
 */
@Service
public class VersionService {
    private static final Logger LOG = LoggerFactory.getLogger(VersionService.class);

    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("yyyyMMddHHmmss").withZone(ZoneId.of("UTC"));

    private final Properties build;

    private Version localVersion;
    private Version latestFinalVersion;
    private Version latestBetaVersion;
    private Instant localBuildDate;
    private String localBuildNumber;

    @Autowired
    private RetryRegistry retryRegistry;

    @Autowired
    private CircuitBreakerRegistry circuitBreakerRegistry;

    public VersionService() throws IOException {
        build = PropertiesLoaderUtils.loadAllProperties("build.properties");
    }

    @PostConstruct
    public void init() {
        io.github.resilience4j.retry.Retry retry = retryRegistry.retry("default");
        RetryConfig config = retry.getRetryConfig();
        LOG.info("Retry max attemps is {}", config.getMaxAttempts());
        retry.getEventPublisher().onRetry(event -> LOG.info("****{}****", event));

        io.github.resilience4j.circuitbreaker.CircuitBreaker circuitBreaker = circuitBreakerRegistry.circuitBreaker("default");
        CircuitBreakerConfig circuitBreakerConfig = circuitBreaker.getCircuitBreakerConfig();
        LOG.info("Circuit breaker minimum number of calls {}", circuitBreakerConfig.getMinimumNumberOfCalls());
        circuitBreaker.getEventPublisher().onCallNotPermitted(event -> LOG.info("****{}****", event));
    }

    /**
     * Time when latest version was fetched (in milliseconds).
     */
    private long lastVersionFetched;

    /**
     * Only fetch last version this often (in milliseconds.).
     */
    private static final long LAST_VERSION_FETCH_INTERVAL = 7L * 24L * 3600L * 1000L; // One week

    /**
     * Returns the version number for the locally installed Airsonic version.
     *
     * @return The version number for the locally installed Airsonic version.
     */
    public Version getLocalVersion() {
        if (localVersion == null) {
            try {
                localVersion = new Version(build.getProperty("version") + "." + build.getProperty("timestamp"));
                LOG.info("Resolved local Airsonic version to: {}", localVersion);
            } catch (Exception x) {
                LOG.warn("Failed to resolve local Airsonic version.", x);
            }
        }
        return localVersion;
    }

    /**
     * Returns the version number for the latest available Airsonic final version.
     *
     * @return The version number for the latest available Airsonic final version, or <code>null</code>
     *         if the version number can't be resolved.
     */
    public synchronized Version getLatestFinalVersion() {
        refreshLatestVersion();
        return latestFinalVersion;
    }

    /**
     * Returns the version number for the latest available Airsonic beta version.
     *
     * @return The version number for the latest available Airsonic beta version, or <code>null</code>
     *         if the version number can't be resolved.
     */
    public synchronized Version getLatestBetaVersion() {
        refreshLatestVersion();
        return latestBetaVersion;
    }

    /**
     * Returns the build date for the locally installed Airsonic version.
     *
     * @return The build date for the locally installed Airsonic version, or <code>null</code>
     *         if the build date can't be resolved.
     */
    public Instant getLocalBuildDate() {
        if (localBuildDate == null) {
            try {
                String date = build.getProperty("timestamp");
                localBuildDate = DATE_FORMAT.parse(date, Instant::from);
            } catch (Exception x) {
                LOG.warn("Failed to resolve local Airsonic build date.", x);
            }
        }
        return localBuildDate;
    }

    /**
     * Returns the build number for the locally installed Airsonic version.
     *
     * @return The build number for the locally installed Airsonic version, or <code>null</code>
     *         if the build number can't be resolved.
     */
    public String getLocalBuildNumber() {
        if (localBuildNumber == null) {
            try {
                localBuildNumber = build.getProperty("revision");
            } catch (Exception x) {
                LOG.warn("Failed to resolve local Airsonic build commit.", x);
            }
        }
        return localBuildNumber;
    }

    /**
     * Returns whether a new final version of Airsonic is available.
     *
     * @return Whether a new final version of Airsonic is available.
     */
    public boolean isNewFinalVersionAvailable() {
        Version latest = getLatestFinalVersion();
        Version local = getLocalVersion();

        if (latest == null || local == null) {
            return false;
        }

        return local.compareTo(latest) < 0;
    }

    /**
     * Returns whether a new beta version of Airsonic is available.
     *
     * @return Whether a new beta version of Airsonic is available.
     */
    public boolean isNewBetaVersionAvailable() {
        Version latest = getLatestBetaVersion();
        Version local = getLocalVersion();

        if (latest == null || local == null) {
            return false;
        }

        return local.compareTo(latest) < 0;
    }

    /**
     * Refreshes the latest final and beta versions.
     */
    private void refreshLatestVersion() {
        // In order to simulate circuit breaker, we're going to fetch latest version from GitHub regardless
        //long now = System.currentTimeMillis();
        //boolean isOutdated = now - lastVersionFetched > LAST_VERSION_FETCH_INTERVAL;

        //if (isOutdated) {
        try {
            //lastVersionFetched = now;
            readLatestVersion();
        } catch (Exception x) {
            LOG.warn("Failed to resolve latest Airsonic version.", x);
        }
        //}
    }

    private static final String VERSION_URL = "https://api.github.com/repos/airsonic-advanced/airsonic-advanced/releases";

    private static ResponseHandler<List<Map<String, Object>>> respHandler = new AbstractResponseHandler<List<Map<String,Object>>>() {
        @Override
        public List<Map<String, Object>> handleEntity(HttpEntity entity) throws IOException {
            try (InputStream is = entity.getContent(); InputStream bis = new BufferedInputStream(is)) {
                return Util.getObjectMapper().readValue(bis, new TypeReference<List<Map<String, Object>>>() {});
            }
        }
    };

    private static Function<Map<String,Object>, Version> releaseToVersionMapper = r ->
            new Version(
                    (String) r.get("tag_name"),
                    (String) r.get("target_commitish"),
                    (Boolean) r.get("draft") || (Boolean) r.get("prerelease"),
                    (String) r.get("html_url"),
                    Instant.parse((String) r.get("published_at")),
                    Instant.parse((String) r.get("created_at")),
                    (List<Map<String,Object>>) r.get("assets")
                    );

    private static int requestCount = 0;

    //@CircuitBreaker(name = "default", fallbackMethod = "readFallbackVersion")
    @Retry(name = "default", fallbackMethod = "readFallbackVersion")
    private Version readLatestVersion() throws IOException, NumberFormatException {
        // Check to see if we should be simulating failure. If it is not set, proceed as usual.
        String retryDemo = System.getenv("AIRSONIC_RETRY_DEMO");
        if (!StringUtils.isEmpty(retryDemo)) {
            int errorRate = Integer.parseInt(retryDemo);
            if (requestCount++ % errorRate == 0)
                throw new IOException("Simulated exception trying to get version info from GitHub");
        }
        LOG.debug("Starting to read latest version");
        RequestConfig requestConfig = RequestConfig.custom()
                .setConnectTimeout(10000)
                .setSocketTimeout(10000)
                .build();
        HttpGet method = new HttpGet(VERSION_URL);
        method.setConfig(requestConfig);
        method.setHeader("accept", "application/vnd.github.v3+json");
        method.setHeader("User-Agent", "Airsonic/" + getLocalVersion());
        List<Map<String, Object>> content;
        try (CloseableHttpClient client = HttpClients.createDefault()) {
            content = client.execute(method, respHandler);
        } catch (ConnectTimeoutException e) {
            LOG.warn("Got a timeout when trying to reach {}", VERSION_URL);
            throw e;
        }

        List<Map<String, Object>> releases = content.stream()
                .sorted(Comparator.<Map<String, Object>,Instant>comparing(r -> Instant.parse((String) r.get("published_at")), Comparator.reverseOrder()))
                .collect(Collectors.toList());

        Optional<Map<String, Object>> betaR = releases.stream().findFirst();
        Optional<Map<String, Object>> finalR = releases.stream().filter(x -> !((Boolean)x.get("draft")) && !((Boolean)x.get("prerelease"))).findFirst();
        Optional<Map<String,Object>> currentR = releases.stream().filter(x ->
                StringUtils.equals(build.getProperty("version") + "." + build.getProperty("timestamp"), (String) x.get("tag_name")) ||
                        StringUtils.equals(build.getProperty("version"), (String) x.get("tag_name"))).findAny();

        LOG.debug("Got {} for beta version", betaR.map(x -> x.get("tag_name")).orElse(null));
        LOG.debug("Got {} for final version", finalR.map(x -> x.get("tag_name")).orElse(null));

        latestBetaVersion = betaR.map(releaseToVersionMapper).orElse(null);
        latestFinalVersion = finalR.map(releaseToVersionMapper).orElse(null);
        localVersion = currentR.map(releaseToVersionMapper).orElse(localVersion);

        return latestBetaVersion;
    }

    private Version readFallbackVersion(Throwable t) {
        LOG.debug("Fallback sets the version to default, IOException: {}", t.toString());
        return null;
    }
}
