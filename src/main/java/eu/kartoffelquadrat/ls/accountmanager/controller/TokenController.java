package eu.kartoffelquadrat.ls.accountmanager.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.common.OAuth2AccessToken;
import org.springframework.security.oauth2.provider.token.TokenStore;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;
import java.util.Collection;

/**
 * ToDo: Update access URLs. Controller that resolves to a user identity / role based on a passed oauth2 token.
 * <p>
 * Sample access: curl "http://127.0.0.1:8084/api/username?access_token=...="
 *
 * @author Maximilian Schiedermeier, August 2020
 */
@RestController
public class TokenController {

    @Autowired
    TokenStore tokenStore;

    /**
     * Resolve logged in user back to her roles, based on token
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping(value = "/oauth/role")
    public Collection<SimpleGrantedAuthority> currentUserRole() {

        // Note: Access to getAuthentication will return null if no corresponding URL pattern is set in ResourceServerConfiguration
        return (Collection<SimpleGrantedAuthority>) SecurityContextHolder.getContext().getAuthentication().getAuthorities();
    }

    /**
     * Resolve logged in user back to username based on token
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping(value = "/oauth/username")
    public String currentUserName(Principal principal) {
        return principal.getName();
    }

    /**
     * Endpoint to revoke an existing OAuth2 token (and the associated refresh token). Must be called on logout and user
     * deletion. Can only be called by the token owner.
     */
    @PreAuthorize("isAuthenticated()")
    @DeleteMapping("/oauth/active")
    public ResponseEntity revokeOwnTokens(Principal principal) {

        String callerName = principal.getName();
        boolean success = revokeTokensByName(callerName);
        if (success)
            return ResponseEntity.status(HttpStatus.OK).body(null);
        else
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("There are no active tokens for the requested user.");
    }

    /**
     * Method to actually discard the tokens. Is also required by Account-Controller uppon user deletion.
     *
     * @param name as the name of the user whose tokens shall be revoked.
     */
    public boolean revokeTokensByName(String name) {
        Collection<OAuth2AccessToken> adminAccessTokens = tokenStore.findTokensByClientIdAndUserName("bgp-client-name", name);
        //tokenStore.
        if (adminAccessTokens != null && !adminAccessTokens.isEmpty()) {
            for (OAuth2AccessToken accessToken : adminAccessTokens) {
                tokenStore.removeRefreshToken(accessToken.getRefreshToken());
                tokenStore.removeAccessToken(accessToken);
            }
            return true;
        } else
            return false;
    }
}
