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

import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import org.airsonic.player.component.ExternalAPICaller;
import org.airsonic.player.domain.Version;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.time.Instant;

/**
 * Provides version-related services, including functionality for determining whether a newer
 * version of Airsonic is available.
 *
 * @author Sindre Mehus
 */
@RestController
public class VersionService {

    private final ExternalAPICaller externalAPICaller;

    private static final Logger LOG = LoggerFactory.getLogger(VersionService.class);

    @Autowired
    public VersionService(ExternalAPICaller externalApi) throws IOException {
        this.externalAPICaller = externalApi;
    }

    /**
     * Returns the version number for the locally installed Airsonic version.
     *
     * @return The version number for the locally installed Airsonic version.
     */
    public Version getLocalVersion() {
        return externalAPICaller.getLocalVersion();
    }

    /**
     * Returns the build date for the locally installed Airsonic version.
     *
     * @return The build date for the locally installed Airsonic version, or <code>null</code>
     *         if the build date can't be resolved.
     */
    public Instant getLocalBuildDate() {
        return externalAPICaller.getLocalBuildDate();
    }

    /**
     * Returns the build number for the locally installed Airsonic version.
     *
     * @return The build number for the locally installed Airsonic version, or <code>null</code>
     *         if the build number can't be resolved.
     */
    public String getLocalBuildNumber() {
        return externalAPICaller.getLocalBuildNumber();
    }

    /**
     * Returns whether a new final version of Airsonic is available.
     *
     * @return Whether a new final version of Airsonic is available.
     */
    @Retry(name = "retryApi", fallbackMethod = "isNewVersionAvailableFallback")
    @CircuitBreaker(name = "CircuitBreakerService")
    @GetMapping("/isNewFinalVersionAvailable")
    public boolean isNewFinalVersionAvailable() {
        return externalAPICaller.isNewFinalVersionAvailable();
    }

    /**
     * Returns whether a new beta version of Airsonic is available.
     *
     * @return Whether a new beta version of Airsonic is available.
     */
    @Retry(name = "retryApi", fallbackMethod = "isNewVersionAvailableFallback")
    @CircuitBreaker(name = "CircuitBreakerService")
    @GetMapping("/isNewBetaVersionAvailable")
    public boolean isNewBetaVersionAvailable() {
        return externalAPICaller.isNewBetaVersionAvailable();
    }

    /**
     * Returns the version number for the latest available Airsonic beta version.
     *
     * @return The version number for the latest available Airsonic beta version, or <code>null</code>
     *         if the version number can't be resolved.
     */
    @Retry(name = "retryApi", fallbackMethod = "getVersionFallback")
    public synchronized Version getLatestBetaVersion() {
        return externalAPICaller.getLatestBetaVersion();
    }

    /**
     * Returns the version number for the latest available Airsonic final version.
     *
     * @return The version number for the latest available Airsonic final version, or <code>null</code>
     *         if the version number can't be resolved.
     */
    @Retry(name = "retryApi", fallbackMethod = "getVersionFallback")
    public synchronized Version getLatestFinalVersion() {
        return externalAPICaller.getLatestFinalVersion();
    }

    /**
     * Handles fallback for calls to check whether updated versions exist
     *
     * @param t Exception returned from the failed Resilience4j-protected call
     *          to GitHub to look for updated version information.
     * @return false, we will ignore new remote versions if the call fails
     */
    public boolean isNewVersionAvailableFallback(Throwable t) {
        return false;
    }

    /**
     * Handles fallback for calls to get version identifier
     *
     * @param t Exception return from failed call to get version
     * @return the local version information
     */
    public Version getVersionFallback(Throwable t) {
        return externalAPICaller.getLocalVersion();
    }
}
