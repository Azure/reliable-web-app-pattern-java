# Active Directory

Airsonic uses [Azure Active Directory (AAD)](https://learn.microsoft.com/en-us/azure/active-directory/develop/) as the identity platform to sign in users.  

## Adding authentication to Airsonic running on Azure App Service

App Service provides built-in authentication and authorization support, so you can sign in users and access data by writing minimal or no code in your web app.  The steps below shows how to secure Airsonic with the App Service authentication/authorization module by using Azure Active Directory (Azure AD) as the identity provider.

## Configure Airsonic Web App Using Terraform

The [Quickstart: Register an application with the Microsoft identity platform](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app) was used to guide the changes needed for Terraform.

### App Registration

```json
resource "azuread_application" "app_registration" {
  display_name     = "${azurecaf_name.app_service.result}-app"
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"  # single tenant
}
```
<sup>Sample code demonstrates how to configure App Registration, [link to main.tf](https://github.com/Azure/reliable-web-app-pattern-java/blob/eb73a37be3d011112286df4e5853228f55cb377f/terraform/modules/app-service/main.tf#L80).</sup>

### App Roles

We define 3 app roles, *Admin*, *User*, and *Creator*. The *Admin* role is allowed to configure the overall application settings for Airsonic. The *Creator* role is allowed to upload videos and create playlists.  The *User* Role is allowed to view the videos. Use following guide [add app roles in your application](https://docs.microsoft.com/azure/active-directory/develop/howto-add-app-roles-in-azure-ad-apps) to understand the concept of `App Roles`.

```json
app_role {
    allowed_member_types = ["User"]
    description          = "Admins can manage perform all task actions"
    display_name         = "Admin"
    enabled              = true
    id                   = random_uuid.admin_role_id.result
    value                = "Admin"
  }

  app_role {
    allowed_member_types = ["User"]
    description          = "ReadOnly roles have limited query access"
    display_name         = "ReadOnly"
    enabled              = true
    id                   = random_uuid.user_role_id.result
    value                = "User"
  }

  app_role {
    allowed_member_types = ["User"]
    description          = "Creator roles allows users to create content"
    display_name         = "Creator"
    enabled              = true
    id                   = random_uuid.creator_role_id.result
    value                = "Creator"
  }
```
<sup>Sample code demonstrates how to configure App Roles, [link to main.tf](https://github.com/Azure/reliable-web-app-pattern-java/blob/eb73a37be3d011112286df4e5853228f55cb377f/terraform/modules/app-service/main.tf#L98).</sup>

### AAD Authentication and Authorization Airsonic Code Changes

Enabling the `appRoles` feature in AAD, `roles` claim generated from `appRoles` is decorated with prefix `APPROLE_`. presents the id_token's `roles` claim.

1. pom.xml

    ```xml
    <dependency>
        <groupId>com.azure.spring</groupId>
        <artifactId>spring-cloud-azure-starter-active-directory</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-oauth2-client</artifactId>
    </dependency>
    ```
1. Refactor GlobalSecurityConfig.java

    Adding Authentication was done by extending the `AadWebSecurityConfigurerAdapter` class and allowing only the roles configured in AAD.

    ```java
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
                    .hasAnyAuthority("APPROLE_User", "APPROLE_Admin", "APPROLE_Creator")
                    .antMatchers("/generalSettings*", "/advancedSettings*", "/userSettings*",
                            "/musicFolderSettings*", "/databaseSettings*", "/transcodeSettings*", "/rest/startScan*")
                    .hasAnyAuthority("APPROLE_User", "APPROLE_Admin")
                    .antMatchers("/deletePlaylist*", "/savePlaylist*")
                    .hasAnyAuthority("APPROLE_Creator")
                    .antMatchers("/download*")
                    .hasAnyAuthority("APPROLE_User", "APPROLE_Creator")
                    .antMatchers("/upload*")
                    .hasAnyAuthority("APPROLE_Creator")
                    .antMatchers("/createShare*")
                    .hasAnyAuthority("APPROLE_Creator")
                    .antMatchers("/changeCoverArt*", "/editTags*")
                    .hasAnyAuthority("APPROLE_Creator")
                    .antMatchers("/setMusicFileInfo*")
                    .hasAnyAuthority("APPROLE_Creator")
                    .antMatchers("/podcastReceiverAdmin*")
                    .hasAnyAuthority("APPROLE_Creator")
                    .antMatchers("/**")
                    .hasAnyAuthority("APPROLE_User", "APPROLE_Admin", "APPROLE_Creator")
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
    ``` 

1. Implement a Spring Filter to add authenticated users to Airsonic DB.

    ```java
    public class AADAddAuthorizedUsersFilter extends OncePerRequestFilter {
        @Override
        protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {

            LOG.debug("In the AADAddAuthorizedUsersFilter filter");

            // Add the user to the User database table if and only if they have a valid app role.
            if (isAirsonicUser(request)) {
                LOG.debug("user is an airsonic user");
                addUserToDatabase(request);
            }

            LOG.debug("AADAddAuthorizedUsersFilter calling doFilter");
            filterChain.doFilter(request, response);
        }
    }
    ```


## Resources

* https://learn.microsoft.com/en-us/azure/developer/java/spring-framework/spring-boot-starter-for-azure-active-directory-developer-guide

* https://learn.microsoft.com/en-us/azure/developer/java/spring-framework/configure-spring-boot-starter-java-app-with-azure-active-directory

* https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-add-app-roles-in-azure-ad-apps
