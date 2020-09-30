package eu.kartoffelquadrat.ls.lobby.model;

import eu.kartoffelquadrat.asyncrestlib.BroadcastContent;
import eu.kartoffelquadrat.ls.gameregistry.controller.LocationValidator;
import eu.kartoffelquadrat.ls.gameregistry.model.GameServerParameters;
import eu.kartoffelquadrat.ls.lobby.control.SessionException;

import java.util.*;

/**
 * Represents a session as maintained by the BGP. Sessions bind players together for a specific game. The lifecycle is
 * opened, launched, removed. OR opened, removed.
 */
public class Session implements BroadcastContent {

    private final GameServerParameters gameParameters;
    private final String creator;
    private final LinkedList<String> players;
    private boolean launched;

    // savegameid is optional. Only relevant, if the session originates a registered savegame.
    private String savegameid;

    // playerLocations is optional. Only relevant if the gameserver registered in P2P mode. Can not replace original players list, for the order in the players-list is relevant.
    // Note: this map is not filled by constructor, but through an additional addPlayerLocation call.
    private Map<String, String> playerLocations;

    /**
     * Constructor to create a standard session (not originating a savegame).
     * @param creator
     * @param gameParameters
     */
    public Session(String creator, GameServerParameters gameParameters) {
        this.creator = creator;
        this.gameParameters = gameParameters;
        players = new LinkedList<>();
        players.add(creator);
        launched = false;
        playerLocations = new LinkedHashMap<>();
    }

    /**
     * Constructor to create a branded session from a savegame.
     * @param gameParameters
     * @param creator
     * @param savegameid
     */
    public Session(String creator, GameServerParameters gameParameters, String savegameid) {
        this.gameParameters = gameParameters;
        this.creator = creator;
        this.players = new LinkedList<>();
        players.add(creator);
        this.savegameid = savegameid;
        launched = false;
        playerLocations = new LinkedHashMap<>();
    }

    /**
     * Registers a player location (IP). Only relevant if the associated game server is registered as P2P phantom.
     * @param player must be a registered player.
     * @param location must be a valid IP address.
     */
    public void addPlayerLocation(String player, String location) throws SessionException {

        if(!players.contains(player))
            throw new SessionException("Player locator can not be added. The player is not registered to this session.");

        if(!LocationValidator.isValidClientLocation(location))
            throw new SessionException("Player locator can not be added. The provided location is not a valid IP address.");

        playerLocations.put(player, location);
    }

    public boolean isFull() {
        return players.size() >= gameParameters.getMaxSessionPlayers();
    }

    public String getGameName() {
        return gameParameters.getName();
    }

    public String getCreator() {
        return creator;
    }

    public List<String> getPlayers() {
        return Collections.unmodifiableList(players);
    }

    public void addPlayer(String playerid) {
        if (isFull())
            throw new RuntimeException("Player cannot be added to session. Session is already full.");
        players.add(playerid);
    }

    public boolean isLaunched() {
        return launched;
    }

    public void markAsLaunched() {
        if (launched)
            throw new RuntimeException("Session cannot be marked as launched, because is it already launched.");
        launched = true;
    }

    public void removePlayer(String player) {
        if(!players.contains(player))
            throw new RuntimeException("Player can not be removed, because she is not registered to the session.");
        players.remove(player);
    }

    public GameServerParameters getGameParameters() {
        return gameParameters;
    }

    public String getSavegameid() {
        return savegameid;
    }

    @Override
    public boolean isEmpty() {
        return false;
    }
}
