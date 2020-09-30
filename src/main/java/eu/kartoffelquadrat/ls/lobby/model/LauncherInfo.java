package eu.kartoffelquadrat.ls.lobby.model;

import java.util.LinkedList;

/**
 * This bean is serialized and sen to a registered gameserver, when a session is launched.
 */
public class LauncherInfo {

    // Just for verification, the name of the registered game.
    String gameServer;

    // List of players, in seating order and the preferred colours.
    LinkedList<PlayerInfo> players;

    // Creator of the game. Typically the first player.
    String creator;

    // Optional id of a savegame to load.
    String savegame;

    public LauncherInfo() {
    }

    public LauncherInfo(String gameServer, LinkedList<PlayerInfo> players, String creator) {
        this.gameServer = gameServer;
        this.players = players;
        this.creator = creator;
        savegame = "";
    }

    public LauncherInfo(String gameServer, LinkedList<PlayerInfo> players, String creator, String savegame) {
        this.gameServer = gameServer;
        this.players = players;
        this.creator = creator;
        this.savegame = savegame;
    }

    public String getGameServer() {
        return gameServer;
    }

    public void setGameServer(String gameServer) {
        this.gameServer = gameServer;
    }

    public LinkedList<PlayerInfo> getPlayers() {
        return players;
    }

    public void setPlayers(LinkedList<PlayerInfo> players) {
        this.players = players;
    }

    public String getCreator() {
        return creator;
    }

    public void setCreator(String creator) {
        this.creator = creator;
    }

    public String getSavegame() {
        return savegame;
    }

    public void setSavegame(String savegame) {
        this.savegame = savegame;
    }
}
