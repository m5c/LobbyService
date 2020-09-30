package eu.kartoffelquadrat.ls.lobby.control;

/**
 * Simple bean to store the data passed from client to server upon opening a new session.
 *
 * @author Maximilian Schiedermeier, August 2020
 */
public class CreateGameForm {

    // name of the registered game-service
    private final String game;

    // Name of the player who initiated this session
    private final String creator;

    // Optional field to reference a savegame. If a valid savegameid is provided, the amount of players is fixed.
    private String savegame = "";

    /**
     *
     * @param game as the name of the registered gameserver
     * @param creator as the
     * @param savegame is either the id of a game-service specific savegame, or the empty string.
     */
    public CreateGameForm(String game, String creator, String savegame) {
        this.game = game;
        this.creator = creator;
        this.savegame = savegame;
    }

    public String getGame() {
        return game;
    }

    public String getCreator() {
        return creator;
    }

    public String getSavegame() {
        return savegame;
    }
}
