/**
 * Original source: http://websystique.com/spring-security/secure-spring-rest-api-using-oauth2/
 */
package eu.kartoffelquadrat.ls.accountmanager.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.oauth2.config.annotation.web.configuration.EnableResourceServer;
import org.springframework.security.oauth2.config.annotation.web.configuration.ResourceServerConfigurerAdapter;
import org.springframework.security.oauth2.config.annotation.web.configurers.ResourceServerSecurityConfigurer;

/**
 * Configuration to enable the possibility for role-based access protection for any url starting with /api/*.
 * @author Maximilian Schiedermeier, August 2020
 */
@Configuration
@EnableResourceServer
public class ResourceServerConfiguration extends ResourceServerConfigurerAdapter {

    private static final String RESOURCE_ID = "my_rest_api";

    @Override
    public void configure(ResourceServerSecurityConfigurer resources) {
        resources.resourceId(RESOURCE_ID).stateless(false);
    }

    /**
     * The following ant matcher does not require any specific group affiliation for users who access /api/** prefixed
     * REST endpoints. However, it provides a security-context, which allows targeted overriding with additional group
     * requirements, by placing "@PreAuthorize("hasAuthority('ROLE_ADMIN')")"-annotations in front of REST access points
     * that require further access restrictions.
     * Note: Alternative role requirements can be be expressed with the following syntax:
     * @PreAuthorize("hasAuthority('ROLE_ADMIN') or hasAuthority('ROLE_USER')
     *
     * @param http
     * @throws Exception
     */
    @Override
    public void configure(HttpSecurity http) throws Exception {

        http.authorizeRequests()
                .antMatchers("/api/**")
                .permitAll(); // Allow by default all unauthenticated access to api. (Extra annotation required to delimit access based on roles.)
    }

}