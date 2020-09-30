package eu.kartoffelquadrat.ls.gameregistry.controller;

/**
 * Simple bean to wrap up the information passed from client to BGP upon registration of a new savegame.
 *
 * @author Maximilian Schiedermeier, August 2020
 */
public class Savegame {

    // Encodes the players in specific order, starting with the game creator.
    String[] players;

    // Name of the gameserver, as registered at the BGP;
    String gamename;

    // Unique identifier, that will be sent to the gameserver as additional session start information, if this savegame was loaded by a session.
    String savegameid;

    public Savegame(String[] players, String gamename, String savegameid) {
        this.players = players;
        this.gamename = gamename;
        this.savegameid = savegameid;
    }

    public Savegame() {
    }

    public String[] getPlayers() {
        return players;
    }

    public void setPlayers(String[] players) {
        this.players = players;
    }

    public String getGamename() {
        return gamename;
    }

    public void setGamename(String gamename) {
        this.gamename = gamename;
    }

    public String getSavegameid() {
        return savegameid;
    }

    public void setSavegameid(String savegameid) {
        this.savegameid = savegameid;
    }
}
