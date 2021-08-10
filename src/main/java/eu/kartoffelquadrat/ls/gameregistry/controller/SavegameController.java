package eu.kartoffelquadrat.ls.gameregistry.controller;

import eu.kartoffelquadrat.ls.accountmanager.controller.TokenController;
import eu.kartoffelquadrat.ls.accountmanager.model.PlayerRepository;
import eu.kartoffelquadrat.ls.gameregistry.model.GameServerParameters;
import eu.kartoffelquadrat.ls.gameregistry.model.GameServers;
import eu.kartoffelquadrat.ls.lobby.control.SessionController;
import eu.kartoffelquadrat.ls.lobby.model.Sessions;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.Collection;

/**
 * Rest endpoints for saving / retrieving / deleting save-game information.
 *
 * @author Maximilian Schiedermeier, August 2020
 */
@RestController
public class SavegameController {

    @Autowired
    GameServers gameServers;

    @Autowired
    PlayerRepository playerRepository;

    @Autowired
    Sessions sessions;

    @Autowired
    SessionController sessionController;

    @Autowired
    TokenController tokenController;

    @PreAuthorize("isAuthenticated()")
    @GetMapping(value = "/api/gameservices/{gameservice}/savegames", produces = "application/json; charset=utf-8")
    public ResponseEntity getSavegamesForGameservice(@PathVariable String gameservice) {

        try {
            verifyIsRegisteredGameService(gameservice);
            Collection<Savegame> savegames = gameServers.getSafegamesForGameServer(gameservice).getAllSavegames();
            return ResponseEntity.status(HttpStatus.OK).body(savegames);
        } catch (SavegameException se) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(se.getMessage());
        }
    }

    @PreAuthorize("hasAnyAuthority('ROLE_SERVICE','ROLE_ADMIN')")
    @DeleteMapping("/api/gameservices/{gameservice}/savegames")
    public ResponseEntity deleteAllSavegamesForGameservice(@PathVariable String gameservice, Principal principal) {

        // In case of a service token used: verify it is the right service.
        String callerRole = tokenController.currentUserRole().toString();
        if (!callerRole.equals("[ROLE_ADMIN]")) {
            if (!principal.getName().equals(gameServers.getRegistringServiceAccountForGame(gameservice)))
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Savegames can only be deleted by the " +
                        "service who also registered the corresponding gameserver.");
        }
        try {
            verifyIsRegisteredGameService(gameservice);
            gameServers.getSafegamesForGameServer(gameservice).removeAll();
            return ResponseEntity.status(HttpStatus.OK).body(null);
        } catch (SavegameException se) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(se.getMessage());
        }
    }

    @PreAuthorize("isAuthenticated()")
    @GetMapping(value = "/api/gameservices/{gameservice}/savegames/{savegameid}", produces = "application/json; charset=utf-8")
    public ResponseEntity getSpecificSafegameForGameservice(@PathVariable String gameservice, @PathVariable String savegameid) {
        try {
            verifyIsRegisteredGameService(gameservice);
            Savegame savegame = gameServers.getSafegamesForGameServer(gameservice).getSavegame(savegameid);
            return ResponseEntity.status(HttpStatus.OK).body(savegame);
        } catch (SavegameException se) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(se.getMessage());
        }
    }

    @PreAuthorize("hasAuthority('ROLE_SERVICE')")
    @PutMapping(value = "/api/gameservices/{gameservice}/savegames/{savegameid}", consumes = "application/json; charset=utf-8")
    public ResponseEntity registerSafegameForGameservice(@PathVariable String gameservice, @PathVariable String savegameid, @RequestBody Savegame savegame, Principal principal) {
        if (!principal.getName().equals(gameServers.getRegistringServiceAccountForGame(gameservice)))
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Savegames can only be deleted by the " +
                    "admin who also registered the corresponding gameserver.");
        try {
            verifyIsRegisteredGameService(gameservice);
            verifySavegameId(savegameid, savegame);
            verifyUsersAndAmountSane(savegame);
            gameServers.getSafegamesForGameServer(gameservice).addSavegame(savegame);
            return ResponseEntity.status(HttpStatus.OK).body(savegame);
        } catch (SavegameException | RegistryException se) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(se.getMessage());
        }
    }

    @PreAuthorize("hasAnyAuthority('ROLE_SERVICE','ROLE_ADMIN')")
    @DeleteMapping("/api/gameservices/{gameservice}/savegames/{savegameid}")
    public ResponseEntity deleteSpecificSafegameForGameservice(@PathVariable String gameservice, @PathVariable String savegameid, Principal principal) {

        // In case of a service token used: verify it is the right service.
        String callerRole = tokenController.currentUserRole().toString();
        if (!callerRole.equals("[ROLE_ADMIN]")) {
            if (!principal.getName().equals(gameServers.getRegistringServiceAccountForGame(gameservice)))
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Savegames can only be deleted by the " +
                        "service who also registered the corresponding gameserver.");
        }
        try {

            verifyIsRegisteredGameService(gameservice);
            verifyIsRegisteredSavegame(gameservice, savegameid);
            gameServers.getSafegamesForGameServer(gameservice).removeSavegame(savegameid);

            // Remove all affected (unlaunched) sessions.
            sessionController.removeAllBySavegame(savegameid, gameservice);

            return ResponseEntity.status(HttpStatus.OK).body(null);
        } catch (SavegameException se) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(se.getMessage());
        }
    }

    private void verifyUsersAndAmountSane(Savegame savegame) throws SavegameException, RegistryException {
        // Verify the provided users exist
        for (String player : savegame.getPlayers()) {
            if (!playerRepository.existsById(player))
                throw new SavegameException("Savegame can not be registered. Not all provided players are valid.");
        }

        // Verify the amount of players is legal for the registered game-type
        GameServerParameters parameter = gameServers.getGameServerParameters(savegame.getGamename());
        int playerAmount = savegame.getPlayers().length;
        if (playerAmount > parameter.getMaxSessionPlayers() || playerAmount < parameter.getMinSessionPlayers())
            throw new SavegameException("Savegame can not be registered. Amount of players is not allowed for the declared game.");
    }

    public void verifySavegameId(String savegameid, Savegame savegame) throws SavegameException {
        if (!savegame.getSavegameid().equals(savegameid))
            throw new SavegameException("Savegame id in URL does not match id in body.");
    }

    public void verifyIsRegisteredGameService(String gameservice) throws SavegameException {
        if (!gameServers.isAlreadyRegisteredName(gameservice))
            throw new SavegameException("No such gameservice: " + gameservice);
    }

    public void verifyIsRegisteredSavegame(String gameservice, String savegameid) throws SavegameException {
        if (!gameServers.isAlreadyRegisteredName(gameservice))
            throw new SavegameException("Can not look up savegameid for unknown game-service: " + gameservice);

        if (!gameServers.getSafegamesForGameServer(gameservice).isExistent(savegameid))
            throw new SavegameException("Can not look up savegame. Not a valid id: " + savegameid);
    }
}
