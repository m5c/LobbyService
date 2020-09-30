package eu.kartoffelquadrat.ls.gameregistry.model;

import eu.kartoffelquadrat.ls.gameregistry.controller.RegistryException;
import eu.kartoffelquadrat.ls.gameregistry.controller.SavegameException;
import eu.kartoffelquadrat.ls.lobby.control.SessionController;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * In-Memory persistence of registered game servers.
 *
 * @author Maximilian Schiedermeier, August 2020
 */
@Component
public class GameServers {

    // stores the IP address of servers for specific game kinds - currently no duplicates supported. We could consider that only per-game load balancing gateways are registered.
    private Map<String, GameServerParameters> registeredGameServers;

    // Stores the name of the admin who registered a game server. Only the same admin is allows to terminate games (launched sessions) or unregister the game service.
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

    public boolean isAlreadyRegistered(String gameName) {
        return registeredGameServers.keySet().contains(gameName);
    }

    public void registerGameServer(String gameName, GameServerParameters params, String adminName) throws RegistryException {
        if (!gameName.equals(params.getName()))
            throw new RegistryException("Name provided in service description must match the registration name.");
        if (isAlreadyRegistered(params.getName())) {
            throw new RegistryException("Service \"" + params.getName() + "\" rejected, because it conflicts with an already registered service.");
        }

        registeredGameServers.put(gameName, params);
        serverAdministrators.put(gameName, adminName);
        savegames.put(gameName, new GameserverSavegames(gameName));
    }

    public void unregisterGameServer(String gameName, String adminName) throws RegistryException {
        if (!isAlreadyRegistered(gameName))
            throw new RegistryException("Can not remove service: \"" + gameName + "\". No such game service is registered.");
        if (!adminName.equals(serverAdministrators.get(gameName)))
            throw new RegistryException("Can not remove service: \"" + gameName + "\". Administrator is not the one who registered the game in the first place.");

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
        if (!isAlreadyRegistered(name))
            throw new RegistryException("Can not look up parameters for game service: \"" + name + "\". No such game service is registered.");
        return registeredGameServers.get(name);
    }

    public String getRegistringAdminForGame(String game)
    {
        return serverAdministrators.get(game);
    }
}
