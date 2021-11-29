package eu.kartoffelquadrat.ls.gameregistry.model;

import eu.kartoffelquadrat.ls.gameregistry.controller.LocationValidator;
import eu.kartoffelquadrat.ls.gameregistry.controller.RegistryException;
import eu.kartoffelquadrat.ls.lobby.control.SessionException;

/**
 * Just a bean to encapsulate all data transferred to the BGP upon registration of a new gameserver.
 */
public class GameServerParameters {

    // Border values allowed for any LS compatible game. No game can register with upper/lower player amount
    // requirements outside these bounds.
    private static final int MAX_LS_GAME_PLAYERS = 10;
    private static final int MIN_LS_GAME_PLAYERS = 2;

    // Name of the gameServer to be registered. Will be converted to lowercase internally. This field should be a unique id without special characters (will be used in URLs)
    private String name;

    // Name of the game as it will be displayed to Lobby Service users. All characters can be used here, including whitespaces.
    private String displayName;

    // Location of the server's base URL. If WebSupport is set to true, this URL must return the webclient of the
    // registered game. In any case the registered game must provide subresource, "games/{gameId}" with "PUT", for the
    // BGP to launch the session on game-server side.
    // Location can be empty, in case the server registration occurred in phantom (P2P) mode. In that case no REST calls
    // are ever sent form the BGP to the associated server. It is then in the responsibility of the P2P clients to
    // observe all relevant BGP resources.
    private String location;

    // Upper and lower bounds for players allowed in sessions of this gameserver.
    private int maxSessionPlayers;
    private int minSessionPlayers;

    /* Indicates whether a generic BGP web clients can page forward to the server location on session launch (gameid as
     session parameter). Encodes a boolean, but must be a string, for non-existence is auto-interpreted as "false" for
     boolean values. If set, convention is that the generic JS client forwards on session launch to the provided server
     location, passing required params such as username, access_token, gameid as URL parameters.*/
    private String webSupport;

    // default CTR required for JSON deserialization.
    public GameServerParameters() {

    }

    /**
     * @param name
     * @param name         as the display name of the registered gameserver (how it will be displayed in a UI).
     * @param location
     * @param minSessionPlayers
     * @param maxSessionPlayers
     */
    public GameServerParameters(String name, String displayName, String location, int minSessionPlayers, int maxSessionPlayers, String webSupport) {
        this.name = name;
        this.displayName = displayName;
        this.location = location;
        this.minSessionPlayers = minSessionPlayers;
        this.maxSessionPlayers = maxSessionPlayers;
        this.webSupport = webSupport;
    }

    /**
     * Private constructor for the creation of player-branded deep copies. Relevant for the loading of sessions from
     * savegames.
     *
     * @param name         as the name of the registered gameserver.
     * @param name         as the display name of the registered gameserver (how it will be displayed in a UI).
     * @param location     as the Base-URL of the registered gameserver.
     * @param playerAmount as the EXACT amount of players required to launch a sessions with these parameters.
     * @param webSupport   as a flag to indicate whether there is a web client that provides a landing page at the
     *                     standardized location.
     */
    private GameServerParameters(String name, String displayName, String location, int playerAmount, String webSupport) {
        this.name = name;
        this.displayName = displayName;
        this.location = location;
        this.minSessionPlayers = playerAmount;
        this.maxSessionPlayers = playerAmount;
        this.webSupport = webSupport;
    }

    public String getName() {
        return name;
    }

    public String getDisplayName() {
        return displayName;
    }

    public String getLocation() {
        return location;
    }

    public int getMaxSessionPlayers() {
        return maxSessionPlayers;
    }

    public int getMinSessionPlayers() {
        return minSessionPlayers;
    }

    public boolean isWebSupport() {
        return Boolean.parseBoolean(webSupport);
    }

    /**
     * Semantic validation of the bean content. Invoked when new game is registered.
     * This does not verify potential collisions with already registered game services.
     */
    public void validate() throws RegistryException {
        StringBuilder problems = new StringBuilder("");

        if (name == null || name.trim().isEmpty())
            problems.append("Name must not be only whitespaces. ");
        if (displayName == null || displayName.trim().isEmpty())
            problems.append("Display-Name must not be only whitespaces. ");
        if(displayName == null || !displayName.trim().equals(displayName))
            problems.append("Provided DisplayName must not contain leading or trailing whitespaces. ");
        if (location == null || !location.isEmpty() && !LocationValidator.isValidGameServiceLocation(location))
            problems.append("Location must be either empty (P2P mode) or contain a valid IP+Port. ");
        if (minSessionPlayers > MAX_LS_GAME_PLAYERS || minSessionPlayers < MIN_LS_GAME_PLAYERS)
            problems.append("Minimum amount of players out of bound. Valid values are within [2..6]. ");
        if (maxSessionPlayers > MAX_LS_GAME_PLAYERS || maxSessionPlayers < MIN_LS_GAME_PLAYERS)
            problems.append("Maximum amount of players out of bound. Valid values are within [2..6]. ");
        if (webSupport == null || !webSupport.equals("true") && !webSupport.equals("false"))
            problems.append("WebSupport must encode a boolean value. ");

        if (!problems.toString().isEmpty())
            throw new RegistryException(problems.toString());
    }

    /**
     * Creates a deep copy of the object, with exception to upper and lower playeramount fixed to the same specific
     * value. This method is relevant when creating sessions from savegames. Loading savegame requires the same amount
     * of players to pick up the game, as were in the original game.
     *
     * @param playerAmount as fixed number of players required to launch the session. Must be within the parent objects
     *                     upper / lower bounds.
     * @return a deep copy of the parent object, with adapted upper and lower playeramount parameters.
     */
    public GameServerParameters getPlayerBrandedCopy(int playerAmount) throws SessionException {

        if (playerAmount <= 0)
            throw new SessionException("Game-parameters can not be forked. Player-amount in savegame must be " +
                    "greater 0.");

        if (playerAmount < minSessionPlayers || playerAmount > maxSessionPlayers)
            throw new SessionException("Game-parameters can not be forked. Player-amount specified in savegame is " +
                    "not within bounds of registered server parameters.");

        // Create a branded deep copy and return it.
        return new GameServerParameters(name, displayName, location, playerAmount, webSupport);
    }

    /**
     * Helper method to determine wether a registered gameserver runs in phantom (p2p) mode. This method simply checks
     * whether no location was provided.
     *
     * @return
     */
    public boolean isPhantom() {
        return location.isEmpty();
    }
}
