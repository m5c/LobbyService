package eu.kartoffelquadrat.ls.gameregistry.controller;

import com.google.gson.Gson;
import eu.kartoffelquadrat.ls.gameregistry.model.GameNameBundle;
import eu.kartoffelquadrat.ls.gameregistry.model.GameServers;
import eu.kartoffelquadrat.ls.gameregistry.model.GameServerParameters;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.Collection;
import java.util.LinkedList;

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
     * Returns array of game name bundles (list of json objects, each entry listing game name and displayname).
     */
    @GetMapping(value = "/api/gameservices", produces = "application/json; charset=utf-8")
    public String getRegisteredGames() throws RegistryException {
        Collection<GameNameBundle> gameNameBundles = new LinkedList<>();
        for (String gameName : gameServers.getGames()) {
            gameNameBundles.add(new GameNameBundle(gameName, gameServers.getGameServerParameters(gameName).getDisplayName()));
        }
        return new Gson().toJson(gameNameBundles);
    }

    /**
     * Endpoint to register a new gameserver at the BGP. Can only be used with a service token.
     *
     * @param gameServiceForm
     */
    @PreAuthorize("hasAuthority('ROLE_SERVICE')")
    @PutMapping(value = "/api/gameservices/{gamename}", consumes = "application/json; charset=utf-8")
    public ResponseEntity registerGameService(@PathVariable String gamename, @RequestBody GameServerParameters gameServiceForm, Principal principal) {

        try {
            gameServiceForm.validate();
            gameServers.registerGameServer(gamename, gameServiceForm, principal.getName());
        } catch (RegistryException r) {
            // Reject registration if there were semantic problems with the provided server data (exception raised by
            // "validate" function).
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(r.getMessage());
        }

        // Otherwise accept registration.
        return ResponseEntity.status(HttpStatus.OK).body(null);
    }

    /**
     * Endpoint to remove a previously registered service. Can only be used with an admin or service token.
     */
    @PreAuthorize("hasAnyAuthority('ROLE_SERVICE','ROLE_ADMIN')")
    @DeleteMapping(value = "/api/gameservices/{gameServiceName}")
    public ResponseEntity unregisterGameService(@PathVariable String gameServiceName) {
        try {
            gameServers.unregisterGameServer(gameServiceName);
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
     * For internal use, only. Unregisters all gameservers registered by a specific service account. Cascade also
     * removes all affected sessions (no matter if running or not)
     *
     * @param name as the identifier of the administrator.
     */
    public void unregisterByService(String name) throws RegistryException {

        for (String game : gameServers.getGames()) {
            if (gameServers.getRegistringServiceAccountForGame(game).equals(name))
                gameServers.unregisterGameServer(game);
        }
    }
}
