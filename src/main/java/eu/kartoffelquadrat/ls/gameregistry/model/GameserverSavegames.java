package eu.kartoffelquadrat.ls.gameregistry.model;

import eu.kartoffelquadrat.ls.gameregistry.controller.Savegame;
import eu.kartoffelquadrat.ls.gameregistry.controller.SavegameException;

import java.util.Collection;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Model object to store all savegames for ONE specific game-service, mapped by the savegame ids.
 */
public class GameserverSavegames {

    private String gameServerName;
    private Map<String, Savegame> savegamesmap;

    public GameserverSavegames(String gameServerName)
    {
        this.gameServerName = gameServerName;
        savegamesmap = new LinkedHashMap<>();
    }

    public void addSavegame(Savegame savegame) throws SavegameException
    {
        if(!savegame.getGamename().equals(gameServerName))
            throw new SavegameException("Savegame can not be added. Game server does not match.");

        if(savegamesmap.containsKey(savegame.getSavegameid()))
            throw new SavegameException("Savegame can not be added. Id is already in use.");

        savegamesmap.put(savegame.getSavegameid(), savegame);
    }

    public Savegame removeSavegame(String saveGameId) throws SavegameException
    {
        if(!savegamesmap.containsKey(saveGameId))
            throw new SavegameException("Savegame can not be removed. Invalid id.");

        return savegamesmap.remove(saveGameId);
    }

    public void removeAll()
    {
        savegamesmap.clear();
    }

    public Collection<Savegame> getAllSavegames()
    {
        return Collections.unmodifiableCollection(savegamesmap.values());
    }

    public Savegame getSavegame(String savegameid) throws SavegameException
    {
        if(!isExistent(savegameid))
            throw new SavegameException("Savegame can not be looked up. Invalid id.");
        return savegamesmap.get(savegameid);
    }

    public boolean isExistent(String savegameid) {
        return savegamesmap.containsKey(savegameid);
    }
}
