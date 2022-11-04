package eu.kartoffelquadrat.ls.accountmanager.controller;

import com.google.gson.Gson;
import eu.kartoffelquadrat.ls.accountmanager.model.Player;
import eu.kartoffelquadrat.ls.accountmanager.model.PlayerRepository;
import eu.kartoffelquadrat.ls.gameregistry.controller.RegistryController;
import eu.kartoffelquadrat.ls.gameregistry.controller.RegistryException;
import eu.kartoffelquadrat.ls.lobby.control.SessionController;
import java.security.Principal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/**
 * Rest controller for all account-related operations. Covers account related,
 * "/api/users/**"-prefixed resources.
 *
 * @author Maximilian Schiedermeier, August 2020
 */

@RestController
public class AccountController {

  @Autowired
  BCryptPasswordEncoder passwordEncoder;
  @Autowired
  TokenController tokenController;
  @Autowired
  SessionController sessionController;
  @Autowired
  private PlayerRepository playerRepository;
  @Autowired
  private RegistryController registryController;

  @PreAuthorize("hasAuthority('ROLE_ADMIN')")
  @GetMapping(value = "/api/users", produces = "application/json; charset=utf-8")
  public String getAllPlayerNames() {
    return new Gson().toJson(playerRepository.findAll());
  }

  /**
   * Player ids are idempotent. Therefore the PUT occurs on the sub resource (player herself).
   *
   * @return
   */
  @PreAuthorize("hasAuthority('ROLE_ADMIN')")
  @PutMapping("/api/users/{username}")
  public ResponseEntity registerPlayer(@RequestBody AccountForm accountForm,
                                       @PathVariable String username) {

    try {
        if (!accountForm.name.equals(username)) {
            throw new AccountException("Username mismatch, comparing body and URL parameters.");
        }

      accountForm.validate();
      if (playerRepository.findById(accountForm.name).isPresent()) {
        throw new AccountException("Name already taken.");
      }
    } catch (AccountException ae) {
      return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ae.getMessage());
    }

    // Looks good. Persist the player
    Player player = new Player(accountForm.name, accountForm.preferredColour,
        passwordEncoder.encode(accountForm.password), accountForm.role);
    playerRepository.save(player);
    return ResponseEntity.ok("Player added.");
  }

  /**
   * Delete a specific account from the database, identified by name. If the account ais associated
   * with running sessions then this implicitly cascade removes those sessions. In case of an (admin
   * or) player: remove all sessions where this player is involved In case of a service: Remove all
   * sessions associated to this service account.
   *
   * @param name as the username of the user-record to be deleted
   * @return
   */
  @PreAuthorize("hasAnyAuthority('ROLE_PLAYER','ROLE_ADMIN')")
  @DeleteMapping("/api/users/{name}")
  public ResponseEntity deleteAccount(@PathVariable String name, Principal principal) {

      if (!playerRepository.findById(name).isPresent()) {
          return ResponseEntity.status(HttpStatus.BAD_REQUEST)
              .body("User cannot be deleted. Does not exist.");
      }

    // if user is admin, forbid self removal. (so there is always at least one admin around)
    Player targetAccount = playerRepository.findById(name).get();
    String callerRole = tokenController.currentUserRole().toString();
      if (principal.getName().equals(name) && callerRole.equals("[ROLE_ADMIN]")) {
          return ResponseEntity.status(HttpStatus.BAD_REQUEST)
              .body("Admins are not allowed to remove themselves.");
      }

    // revoke active tokens of users in case they have not yet expired
    tokenController.revokeTokensByName(name);

    // If account (to be removed) belongs to a service, remove all gameservers registered by that account. Cascades: also removes all sessions of the affected gameservers
    if (targetAccount.getRole().toString().contains("ROLE_SERVICE")) {
      try {
        registryController.unregisterByService(name);
      } catch (RegistryException re) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(
            "Implicit of removal of associated games and sessions failed due to service identifier mismatch.");
      }
    } else {
      // Else: account (to be removed) belongs to a player or admin: Remove player from all un-launched sessions where she is enrolled, but not the creator. Remove all other
      // affected sessions and notify listeners and game-servers where required.
      try {
        sessionController.removePlayerFromAllSessions(name);
      } catch (RegistryException re) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(re.getMessage());
      } // delete user from database
    }
    playerRepository.deleteById(name);

    return ResponseEntity.status(HttpStatus.OK).body(null);
  }

  /**
   * Update method for a player/admin password. Requires authentication by token
   *
   * @param name as the player name, for who the password shall be updated.
   */
  @PreAuthorize("isAuthenticated()")
  @PostMapping(value = "/api/users/{name}/password", consumes = "application/json; charset=utf-8")
  public ResponseEntity updatePassword(@PathVariable String name,
                                       @RequestBody PasswordForm passwordForm,
                                       Principal principal) {
    // Verify the user exists
      if (!playerRepository.existsById(name)) {
          return ResponseEntity.status(HttpStatus.BAD_REQUEST)
              .body("Password can not be updated. No such user.");
      }

    // Verify the caller has the privilege to modify the password.
    String callerRole = tokenController.currentUserRole().toString();
      if (!callerRole.contains("ADMIN") && !principal.getName().equals(name)) {
          return ResponseEntity.status(HttpStatus.BAD_REQUEST)
              .body("Only admins can update the password of other users.");
      }

    // Verify the provided new password fulfills the password criteria
      if (!AccountForm.validatePasswordString(passwordForm.getNextPassword())) {
          return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(
              "Does not comply to password policy. (At least one uppercase, one lowercase, one number and one special character required.)");
      }

    // Verify the new password is different from the old password
      if (passwordForm.getNextPassword().equals(passwordForm.getOldPassword())) {
          return ResponseEntity.status(HttpStatus.BAD_REQUEST)
              .body("New password must not be identical to old password.)");
      }

    // Verify the provided previous password is correct - this check is only performed if a non-admin token was used.
    Player player = playerRepository.findById(name).get();
    if (!callerRole.contains("ADMIN")) {
        if (!passwordEncoder.matches(passwordForm.getOldPassword(), player.getPassword())) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body("Password can not be updated. Provided old password is incorrect.");
        }
    }

    // Actually update the password. (Store the encoded password, not tha blank next password.)
    player.setPassword(passwordEncoder.encode(passwordForm.getNextPassword()));
    playerRepository.save(player);
    return ResponseEntity.status(HttpStatus.OK).body(null);
  }

  /**
   * Update method for a user's preferred colour. Requires authentication. Can only be changed by an
   * admin or the player herself. ProAuthorize does not cover services, because services have no
   * colours and should not be allowed to modify the default field (white).
   *
   * @param name as the player name, for who the colour shall be updated.
   */
  @PreAuthorize("hasAnyAuthority('ROLE_PLAYER','ROLE_ADMIN')")
  @PostMapping(value = "/api/users/{name}/colour", consumes = "application/json; charset=utf-8")
  public ResponseEntity updateColour(@PathVariable String name, @RequestBody ColourForm colourForm,
                                     Principal principal) {
    // Verify the user exists
      if (!playerRepository.existsById(name)) {
          return ResponseEntity.status(HttpStatus.BAD_REQUEST)
              .body("Colour can not be updated. No such user.");
      }

    // Verify the caller has the privilege to modify the password. (only admin and self allowed)
    String callerRole = tokenController.currentUserRole().toString();
      if (!callerRole.contains("ADMIN") && !principal.getName().equals(name)) {
          return ResponseEntity.status(HttpStatus.BAD_REQUEST)
              .body("Colour can not be altered on behalf of another user.");
      }

    // Verify the provided new colour fulfills the hexadecimal colour-string criteria
    Player player = playerRepository.findById(name).get();
      if (!AccountForm.validateColourString(colourForm.getColour())) {
          return ResponseEntity.status(HttpStatus.BAD_REQUEST)
              .body("Provided colour is not a valid Hexadecimal colour-string.");
      }

    // Actually update the colour.
    player.setPreferredColour(colourForm.getColour());
    playerRepository.save(player);
    return ResponseEntity.status(HttpStatus.OK).body(null);
  }

  /**
   * Query method for a user's preferred colour. Requires authentication. The PreAuthorize filter
   * excludes services, because those accounts at no point need colours.
   *
   * @param name as the player name, for who the colour shall be retrieved.
   */
  @PreAuthorize("hasAnyAuthority('ROLE_PLAYER','ROLE_ADMIN')")
  @GetMapping(value = "/api/users/{name}/colour", produces = "application/json; charset=utf-8")
  public ResponseEntity getPreferredColour(@PathVariable String name, Principal principal) {
    // Verify the user exists
      if (!playerRepository.existsById(name)) {
          return ResponseEntity.status(HttpStatus.BAD_REQUEST)
              .body("Colour can not be queried. No such user.");
      }

    // Verify the caller has the privilege to query the colour.
    String callerRole = tokenController.currentUserRole().toString();
      if (!callerRole.contains("ADMIN") && !principal.getName().equals(name)) {
          return ResponseEntity.status(HttpStatus.BAD_REQUEST)
              .body("Colour can not be queried on behalf of another user.");
      }

    ColourForm colourForm =
        new ColourForm(playerRepository.findById(name).get().getPreferredColour());
    return ResponseEntity.status(HttpStatus.OK).body(colourForm);
  }

  /**
   * Query method for user details of a specific user. Requires authentication. Only accessible to
   * the user herself and admins.
   *
   * @param name as the player name, for who the colour shall be retrieved.
   */
  @PreAuthorize("isAuthenticated()")
  @GetMapping(value = "/api/users/{name}", produces = "application/json; charset=utf-8")
  public ResponseEntity queryUserDetails(@PathVariable String name, Principal principal) {

    // Verify the user exists
      if (!playerRepository.existsById(name)) {
          return ResponseEntity.status(HttpStatus.BAD_REQUEST)
              .body(new ErrorForm("User details can not be queried. No such user."));
      }

    // Verify the caller has the privilege to query the user details.
    String callerRole = tokenController.currentUserRole().toString();
      if (!callerRole.contains("ADMIN") && !principal.getName().equals(name)) {
          return ResponseEntity.status(HttpStatus.BAD_REQUEST)
              .body(new ErrorForm("User details can only be queried by admins or user themself."));
      }

    // Actually return the user details.
    return ResponseEntity.status(HttpStatus.OK).body(playerRepository.findById(name).get());
  }
}
