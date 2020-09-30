package eu.kartoffelquadrat.ls.lobby.model;

import eu.kartoffelquadrat.asyncrestlib.BroadcastContent;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.Map.Entry;

/**
 * In memory data layout of lobby service. There should be only one entity of this class.
 *
 * @author Maximilian Schiedermeier, August 2020
 */
@Component
public class Sessions implements BroadcastContent {

    private Map<Long, Session> sessions;

    public Sessions() {
        this.sessions = new LinkedHashMap<>();
    }

    public Session getSessionById(long sessionId) {
        return sessions.get(sessionId);
    }

    /**
     * We explicitly also want to propagate updates of "no-available" sessions. Therefore we always return "false" here,
     * to override the ARL's "isEmpty" check.
     *
     * @return
     */
    @Override
    public boolean isEmpty() {
        return false;
    }

    public boolean addSession(long sessionId, Session session) {
        if (sessions.containsKey(sessionId))
            throw new RuntimeException("Session cannot be created, id is already in use.");
        sessions.put(sessionId, session);
        return true;
    }

    public Session removeSession(long sessionId) {
        return sessions.remove(sessionId);
    }

    public boolean isExistent(long sessionId) {
        return sessions.keySet().contains(sessionId);
    }

    /**
     * Builds a Collection of all sessionIds where the provided user is the creator.
     *
     * @param creatorName as the user in question, for who the created session id are to be determined.
     * @return
     */
    public Collection<Long> getAllSessionsByCreator(String creatorName) {
        Collection<Long> allSessionsByCreator = new LinkedList<>();
        for (Map.Entry<Long, Session> entry : sessions.entrySet()) {
            if (entry.getValue().getCreator().equals(creatorName))
                allSessionsByCreator.add(entry.getKey());
        }
        return allSessionsByCreator;
    }

    /**
     * Builds a Collection of all sessionIds where the provided user is an enroled player.
     *
     * @param playerName as the user in question, for who the created session id are to be determined.
     * @return
     */
    public Collection<Long> getAllSessionsWithPlayer(String playerName) {
        Collection<Long> allSessionsWithPlayer = new LinkedList<>();
        for (Map.Entry<Long, Session> entry : sessions.entrySet()) {
            if (entry.getValue().getPlayers().contains(playerName))
                allSessionsWithPlayer.add(entry.getKey());
        }
        return allSessionsWithPlayer;
    }

    /**
     * Looks up all sessions that are associated to the provided game server.
     *
     * @param game as the name of the gameserver.
     * @return a collection ofa ll affected session ids.
     */
    public Collection<Long> getAllSessionsByGame(String game) {
        Collection<Long> allSessionsOfGame = new LinkedList<>();
        for (Map.Entry<Long, Session> entry : sessions.entrySet()) {
            if (entry.getValue().getGameParameters().getName().equals(game))
                allSessionsOfGame.add(entry.getKey());
        }
        return allSessionsOfGame;
    }

    /**
     * Returns a map with all unlaunched savegames that match a provided savegameid and gameserver. Required to remove
     * unlaunched sessions when a savegame is unregistered.
     *
     * @param savegameid  as the savegame to look for.
     * @param gameservice as the context provider for the savegameid scope. Savegames ids are only unique for a specific
     *                    gameservice.
     * @return a map with all matching sessions
     */
    public Map<Long, Session> getAllUnlaunchedSessionsBySavegame(String savegameid, String gameservice) {

        Map<Long, Session> matchingSessions = new LinkedHashMap<>();

        for (Entry<Long, Session> entry : sessions.entrySet()) {

            // 3 things must be fulfilled: Must be unlaunched, matching gamerservice, matching savegameid
            Session session = entry.getValue();
            if (!session.isLaunched() && session.getGameParameters().getName().equals(gameservice) && session.getSavegameid().equals(savegameid))
                matchingSessions.put(entry.getKey(), entry.getValue());
        }
        return matchingSessions;
    }
}
