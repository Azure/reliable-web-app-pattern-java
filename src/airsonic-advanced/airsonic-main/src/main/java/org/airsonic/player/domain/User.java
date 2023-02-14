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
package org.airsonic.player.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import org.airsonic.player.util.Util;

import java.util.Collections;
import java.util.Set;

/**
 * Represent a user.
 *
 * @author Sindre Mehus
 */
public class User {

    public static final String USERNAME_ADMIN = "admin";
    public static final String USERNAME_GUEST = "guest";
    public static final String USERNAME_ANONYMOUS = "anonymous";

    private final String username;
    private String email;
    private boolean ldapAuthenticated;
    private long bytesStreamed;
    private long bytesDownloaded;
    private long bytesUploaded;
    private Set<Role> roles;

    @JsonCreator(mode = JsonCreator.Mode.PROPERTIES)
    public User(@JsonProperty("username")String username, @JsonProperty("email")String email, @JsonProperty("ldapAuthenticated")boolean ldapAuthenticated,
                @JsonProperty("bytesStreamed")long bytesStreamed, @JsonProperty("bytesDownloaded")long bytesDownloaded, @JsonProperty("bytesUploaded")long bytesUploaded,
                @JsonProperty("roles")Set<Role> roles) {
        this.username = username;
        this.email = email;
        this.ldapAuthenticated = ldapAuthenticated;
        this.bytesStreamed = bytesStreamed;
        this.bytesDownloaded = bytesDownloaded;
        this.bytesUploaded = bytesUploaded;
        this.roles = roles;
    }

    public User(String username, String email) {
        this(username, email, false, 0, 0, 0, Collections.emptySet());
    }

    @JsonProperty("username")
    public String getUsername() {
        return username;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public boolean isLdapAuthenticated() {
        return ldapAuthenticated;
    }

    public void setLdapAuthenticated(boolean ldapAuthenticated) {
        this.ldapAuthenticated = ldapAuthenticated;
    }

    public long getBytesStreamed() {
        return bytesStreamed;
    }

    public void setBytesStreamed(long bytesStreamed) {
        this.bytesStreamed = bytesStreamed;
    }

    public long getBytesDownloaded() {
        return bytesDownloaded;
    }

    public void setBytesDownloaded(long bytesDownloaded) {
        this.bytesDownloaded = bytesDownloaded;
    }

    public long getBytesUploaded() {
        return bytesUploaded;
    }

    public void setBytesUploaded(long bytesUploaded) {
        this.bytesUploaded = bytesUploaded;
    }

    @JsonProperty("roles")
    public Set<Role> getRoles() {
        return roles;
    }

    public void setRoles(Set<Role> roles) {
        this.roles = roles;
    }

    @JsonIgnore
    public boolean isAdminRole() {
        return roles.contains(Role.ADMIN);
    }

    @JsonIgnore
    public boolean isSettingsRole() {
        return roles.contains(Role.SETTINGS);
    }

    @JsonIgnore
    public boolean isCommentRole() {
        return roles.contains(Role.COMMENT);
    }

    @JsonIgnore
    public boolean isDownloadRole() {
        return roles.contains(Role.DOWNLOAD);
    }

    @JsonIgnore
    public boolean isUploadRole() {
        return roles.contains(Role.UPLOAD);
    }

    @JsonIgnore
    public boolean isPlaylistRole() {
        return roles.contains(Role.PLAYLIST);
    }

    @JsonIgnore
    public boolean isCoverArtRole() {
        return roles.contains(Role.COVERART);
    }

    @JsonIgnore
    public boolean isPodcastRole() {
        return roles.contains(Role.PODCAST);
    }

    @JsonIgnore
    public boolean isStreamRole() {
        return roles.contains(Role.STREAM);
    }

    @JsonIgnore
    public boolean isJukeboxRole() {
        return roles.contains(Role.JUKEBOX);
    }

    @JsonIgnore
    public boolean isShareRole() {
        return roles.contains(Role.SHARE);
    }

    @Override
    public String toString() {
        return username + " " + Util.toJson(roles);
    }

    public enum Role {
        ADMIN, SETTINGS, DOWNLOAD, UPLOAD, PLAYLIST, COVERART, COMMENT, PODCAST, STREAM, JUKEBOX, SHARE
    }
}
