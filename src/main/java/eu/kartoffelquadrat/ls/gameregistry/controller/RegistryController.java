package eu.kartoffelquadrat.ls.gameregistry.controller;

import com.google.gson.Gson;
import eu.kartoffelquadrat.ls.gameregistry.model.GameServers;
import eu.kartoffelquadrat.ls.gameregistry.model.GameServerParameters;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;

/**
 * REST controller endpoint for all gameservice related information (with exception to savegames).
 *
 * @author Maximilian Schiedermeier, August 2020
 */
@RestController
public class RegistryController {

    private GameServers gameServers;

    public RegistryController(@Autowired GameServers gameServers) {
        this.gameServers = gameServers;
    }

    /**
     * Returns array of game kinds (stringarray, as single JSON string) for which a server is registered. (Currently
     * exactly one).
     */
    @GetMapping(value = "/api/gameservices", produces = "application/json; charset=utf-8")
    public String getRegisteredGames() {
        return new Gson().toJson(gameServers.getGames());
    }

    /**
     * Endpoint to register a new gameserver at the BGP.
     *
     * @param gameServiceForm
     */
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    @PutMapping(value = "/api/gameservices/{gamename}", consumes = "application/json; charset=utf-8")
    public ResponseEntity registerGameService(@PathVariable String gamename, @RequestBody GameServerParameters gameServiceForm, Principal principal) {

        // Reject registration if there were semantic problems with the provided server data.
        try {
            gameServiceForm.validate();
            gameServers.registerGameServer(gamename, gameServiceForm, principal.getName());
        } catch (RegistryException r) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(r.getMessage());
        }

        // Otherwise accept registration.
        return ResponseEntity.status(HttpStatus.OK).body(null);
    }

    /**
     *
     */
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    @DeleteMapping(value = "/api/gameservices/{gameServiceName}")
    public ResponseEntity unregisterGameService(@PathVariable String gameServiceName, Principal principal) {
        try {
            gameServers.unregisterGameServer(gameServiceName, principal.getName());
        } catch (RegistryException r) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(r.getMessage());
        }
        return ResponseEntity.status(HttpStatus.OK).body(null);
    }

    /**
     * Returns parameters stored for a specific game-service.
     *
     * @param gameservice as the service for which the parameters shall be looked up.
     */
    @GetMapping(value = "/api/gameservices/{gameservice}", produces = "application/json; charset=utf-8")
    public ResponseEntity getRegisteredGames(@PathVariable String gameservice) {

        try {
            return ResponseEntity.status(HttpStatus.OK).body(gameServers.getGameServerParameters(gameservice));
        } catch (RegistryException re) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(re.getMessage());
        }
    }

    /**
     * Unregisters all gameservers registered by a specific admin. Cascade also removes all affected sessions (no matter
     * if running or not)
     *
     * @param name as the identifier of the administrator.
     */
    public void unregisterByAdmin(String name) throws RegistryException {

        for (String game : gameServers.getGames()) {
            if (gameServers.getRegistringAdminForGame(game).equals(name))
                gameServers.unregisterGameServer(game, name);
        }
    }
}
