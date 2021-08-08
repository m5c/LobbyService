package eu.kartoffelquadrat.ls.gameregistry.model;

import eu.kartoffelquadrat.ls.gameregistry.controller.RegistryException;
import eu.kartoffelquadrat.ls.gameregistry.controller.SavegameException;
import eu.kartoffelquadrat.ls.lobby.control.SessionController;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.stream.Stream;

/**
 * In-Memory persistence of registered game servers.
 *
 * @author Maximilian Schiedermeier, August 2020
 */
@Component
public class GameServers {

    // stores the IP address of servers for specific game kinds.
    private Map<String, GameServerParameters> registeredGameServers;

    // Stores the name of the service account who registered a game server.
    // Only the same serice account is allowed to terminate games (launched sessions) or unregister the game service.
    private Map<String, String> serverAdministrators;

    // Stored the registered savegames (by id), per gameserver;
    private Map<String, GameserverSavegames> savegames;

    @Autowired
    SessionController sessionController;

    public GameServers() {
        registeredGameServers = new LinkedHashMap<>();
        serverAdministrators = new LinkedHashMap<>();
        savegames = new LinkedHashMap<>();
    }

    public boolean isAlreadyRegisteredName(String gameName) {
        return registeredGameServers.keySet().contains(gameName);
    }

    /**
     * Check if any of the displayNames of any previously registered server collides the provided display name.
     * @param displayName as a String to search for on all registered games' displayName fiels.
     * @return true if there is a collision with an existing gameService.
     */
    public boolean isAlreadyRegisteredDisplayName(String displayName) {
        Stream<String> registeredDisplayNames = registeredGameServers.values().stream().map(params -> params.getDisplayName());

        // Trimming is not necessary. Previous bean validation rejects display names with leading or trailing whitespaces.
        return registeredDisplayNames.anyMatch(displayNames -> displayNames.contains(displayName));
    }

    public void registerGameServer(String gameName, GameServerParameters params, String serviceAccountName) throws RegistryException {
        if (!gameName.equals(params.getName()))
            throw new RegistryException("Name provided in service description must match the registration name.");

        // Verify if name (id) or displayName are already taken by a previously registered service.
        if (isAlreadyRegisteredName(params.getName()) || isAlreadyRegisteredDisplayName(params.getDisplayName())) {
            throw new RegistryException("Service \"" + params.getName() + "\" rejected, because it conflicts an already registered service.");
        }

        registeredGameServers.put(gameName, params);
        serverAdministrators.put(gameName, serviceAccountName);
        savegames.put(gameName, new GameserverSavegames(gameName));
    }

    public void unregisterGameServer(String gameName) throws RegistryException {
        if (!isAlreadyRegisteredName(gameName))
            throw new RegistryException("Can not remove service: \"" + gameName + "\". No such game service is registered.");

        // Remove all sessions, associated to this game-server. Send DELETE to sessions that are already launched, if required.
        sessionController.removeAllSessionsByGame(gameName);

        // Also remove registered server from internal index.
        registeredGameServers.remove(gameName);

        // Also remove all savegames
        savegames.remove(gameName);
    }

    public String[] getGames() {
        return registeredGameServers.keySet().toArray(new String[registeredGameServers.size()]);
    }

    public GameserverSavegames getSafegamesForGameServer(String gameServer) throws SavegameException
    {
        if(!registeredGameServers.containsKey(gameServer))
            throw new SavegameException("Savegames can not be looked up. Unknown game-server.");

        return savegames.get(gameServer);
    }

    public GameServerParameters getGameServerParameters(String name) throws RegistryException {
        if (!isAlreadyRegisteredName(name))
            throw new RegistryException("Can not look up parameters for game service: \"" + name + "\". No such game service is registered.");
        return registeredGameServers.get(name);
    }

    public String getRegistringServiceAccountForGame(String game)
    {
        return serverAdministrators.get(game);
    }
}
