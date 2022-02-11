package eu.kartoffelquadrat.ls.lobby.control;

import eu.kartoffelquadrat.asyncrestlib.BroadcastContentManager;
import eu.kartoffelquadrat.asyncrestlib.ResponseGenerator;
import eu.kartoffelquadrat.ls.accountmanager.controller.TokenController;
import eu.kartoffelquadrat.ls.accountmanager.model.PlayerRepository;
import eu.kartoffelquadrat.ls.gameregistry.controller.*;
import eu.kartoffelquadrat.ls.gameregistry.model.GameServerParameters;
import eu.kartoffelquadrat.ls.gameregistry.model.GameServers;
import eu.kartoffelquadrat.ls.lobby.model.LauncherInfo;
import eu.kartoffelquadrat.ls.lobby.model.PlayerInfo;
import eu.kartoffelquadrat.ls.lobby.model.Sessions;
import eu.kartoffelquadrat.ls.lobby.model.Session;
import kong.unirest.Unirest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.context.request.async.DeferredResult;

import java.security.Principal;
import java.util.*;
import java.util.Map.Entry;

/**
 * Controller class for the overview of unlaunched, and creatable sessions.
 *
 * @author Maximilian Schiedermeier, August 2020
 */
@RestController
public class SessionController {


    // Note: Ideally this object is loaded from a DB on service startup. For now it is created empty and within memory.
    Sessions sessions;

    @Value("${long.poll.timeout}")
    int longPollTimeout;

    @Value("${api.games.url}")
    String apiGamesUrl;

    @Autowired
    PlayerRepository playerRepository;
    // Entity that tells up-to date game creation option.
    // Note: We consider that game kinds change only very slowly, so there is no to update list displayed in UI asynchronously.
    @Autowired
    GameServers gameServers;

    @Autowired
    TokenController tokenController;

    @Autowired
    SavegameController savegameController;

    private BroadcastContentManager<Sessions> sessionBroadcastManager;
    private Map<Long, BroadcastContentManager<Session>> sessionSpecificBroadcastManagers;

    private Logger logger;

    @Autowired
    public SessionController(Sessions sessions) {
        this.sessions = sessions;
        sessionBroadcastManager = new BroadcastContentManager<>(sessions);
        sessionSpecificBroadcastManagers = new LinkedHashMap<>();
        logger = LoggerFactory.getLogger(SessionController.class);
    }

    /**
     * Start a new session. Note: We use a "POST on a collection resource" here, because the client does not know the id
     * of the resource to be created.
     *
     * @param createGameForm as parameter payload for the game session to be created
     * @param principal      implicitly provided token owner information (spring security)
     * @param location       optional string that encodes clients IP address. Only relevant if corresponding game-server
     *                       was registered in phantom (P2P) mode.
     * @return
     */
    @PreAuthorize("hasAnyAuthority('ROLE_PLAYER','ROLE_ADMIN')")
    @PostMapping("/api/sessions")
    public ResponseEntity createSession(@RequestBody CreateGameForm createGameForm, Principal principal, @RequestParam(required = false) String location) {

        logger.info("Received create session request.");

        // Verify the game is actually offered (registered), no phony call
        GameServerParameters gameParameters;
        try {
            gameParameters = gameServers.getGameServerParameters(createGameForm.getGame());
            if (!createGameForm.getCreator().equals(principal.getName()))
                throw new RegistryException("Creator must be identical to token owner.");
        } catch (RegistryException re) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Session can not be created. No such game server is registered.");
        }

        // In case of a P2P game, verify a location was provided, register it.
        if (gameParameters.isPhantom()) {
            if (location == null || location.trim().isEmpty())
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Session for P2P game can not be created without providing client location.");
            if (!LocationValidator.isValidClientLocation(location))
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Provided client location is not a valid IP.");
        }

        // Reject locations if the associated game is not in p2p mode.
        else if (!(location == null || location.isEmpty()))
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Setting a client location is not allowed for non p2p games.");


        // Generic parts of the sessions creation - no matter if created from scratch or from a savegame.
        long sessionId = generateUniqueSessionId();
        String creator = principal.getName();
        Session session;

        // Standard case, just a new session. Create it, index it.
        String savegameid = createGameForm.getSavegame();
        if (savegameid.trim().isEmpty())
            session = new Session(creator, gameParameters, savegameid);
        else {
            // Session is created from a savegame...
            String gameservice = createGameForm.getGame();

            try {
                // Verify gameserver and savegame do exist
                savegameController.verifyIsRegisteredGameService(gameservice);
                savegameController.verifyIsRegisteredSavegame(gameservice, savegameid);

                // Actually look up savegame by id
                Savegame savegame = gameServers.getSafegamesForGameServer(gameservice).getSavegame(savegameid);

                // Create a new session, with parameter from savegame (player amount, game kind)
                GameServerParameters brandedParams = gameParameters.getPlayerBrandedCopy(savegame.getPlayers().length);
                session = new Session(creator, brandedParams, createGameForm.getSavegame());

            } catch (SavegameException | SessionException se) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(se.getMessage());
            }
        }

        // In case the session runs in phantom/p2p mode, attach the provided creator location to the session
        if (location != null && !location.isEmpty())
            try {
                session.addPlayerLocation(creator, location);
            } catch (SessionException se) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Unable to attach provided creator location to session.");
            }

        // Register the newly created session, notify async clients about session update.
        sessions.addSession(sessionId, session);
        sessionBroadcastManager.touch();

        // No need for a session specific unlatch here (there can not yet be any observers). We only have to CREATE a
        // corresponding BCM
        BroadcastContentManager<Session> sessionBroadcastContentManager = new BroadcastContentManager<>(session);
        sessionSpecificBroadcastManagers.put(sessionId, sessionBroadcastContentManager);

        logger.info("Approved create session request.");
        return ResponseEntity.status(HttpStatus.OK).body(sessionId);
    }


    /**
     * Removes a session. Can be either a launched session (restricted to administrators, game end), or an unlaunched
     * session (restricted to the session creator).
     */
    @PreAuthorize("isAuthenticated()")
    @DeleteMapping("/api/sessions/{sessionid}")
    public ResponseEntity removeSession(@PathVariable long sessionid, Principal principal) {
        // Verify the session in question actually exists
        if (!sessions.isExistent(sessionid))
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Session can not be deleted. It does not exist.");

        // Verify the caller has the right to delete the session.
        Session session = sessions.getSessionById(sessionid);
        if (!session.isLaunched() && !session.getCreator().equals(principal.getName()))
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Unlaunched sessions can only be deleted by creator.");
        String callerRole = tokenController.currentUserRole().toString();

        // Once launched if an only be killed by an admin, specifically the admin who registered the gameserver
        if (session.isLaunched() && !(callerRole.contains("ADMIN") || callerRole.contains("SERVICE")))
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Launched sessions can only be deleted by admins and services.");

        if( session.isLaunched() && callerRole.contains("SERVICE"))
            if(!principal.getName().equals(gameServers.getRegistringServiceAccountForGame(session.getGameName())))
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Launched sessions can only be deleted by the associated service or an admin.");

        // Launched games can only be terminated by the admin who registered the gameserver.
        if (session.isLaunched() && callerRole.contains("ADMIN"))
            if (!principal.getName().equals(gameServers.getRegistringServiceAccountForGame(session.getGameName())))
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Launched sessions can only be deleted by the admin who registered the corresponding game-server.");

        deleteSessionAndNotifyListeners(sessionid);
        return ResponseEntity.status(HttpStatus.OK).body(null);
    }

    /**
     * Deletes a session and ensures the all-session BCM and session-specific BCM are notified.
     *
     * @param sessionid
     */
    private void deleteSessionAndNotifyListeners(long sessionid) {

        // Looks good, delete the session and update clients
        sessions.removeSession(sessionid);
        sessionBroadcastManager.touch();

        // Terminate and remove BCM of the removed session.
        sessionSpecificBroadcastManagers.remove(sessionid).terminate();
    }

    /**
     * Provides list of currently open (unlaunched) sessions, that can be joined.
     *
     * @param hash
     * @return
     */
    // ASYNC. If no hash is provided, the client is notified upon the next state change. If a hash is provided the result is only deferred, if the hashes match.
    @GetMapping(value = "/api/sessions", produces = "application/json; charset=utf-8")
    public DeferredResult<ResponseEntity<String>> getAllGamesUpdate(@RequestParam(required = false) String hash) {

        // No hash provided at all -> return a synced update. We achieve this by setting a hash that clearly differs from any valid hash.
        if (hash == null)
            hash = "-";

        // Hash was provided, but is empty -> return an asynchronous update, as soon as something has changed
        if (hash.isEmpty())
            ResponseGenerator.getAsyncUpdate(longPollTimeout, sessionBroadcastManager);

        // A hash was provided, or we want to provoke a hash mismatch because no hash (not even an empty hash) was provided
        return ResponseGenerator.getHashBasedUpdate(longPollTimeout, sessionBroadcastManager, hash);
    }

    @GetMapping(value = "/api/sessions/{sessionid}", produces = "application/json; charset=utf-8")
    public DeferredResult<ResponseEntity<String>> getGameUpdate(@PathVariable long sessionid, @RequestParam(required = false) String hash) {

        // reject if the session id does not exist
        if (!sessions.isExistent(sessionid)) {
            DeferredResult<ResponseEntity<String>> deferredResult = new DeferredResult<ResponseEntity<String>>(5000L);
            deferredResult.setResult(ResponseEntity.status(HttpStatus.BAD_REQUEST).body("No updates available. Not a valid session id."));
            return deferredResult;
        }
        // No hash provided at all -> return a synced update. We achieve this by setting a hash that clearly differs from any valid hash.
        if (hash == null)
            hash = "-";

        // Hash was provided, but is empty -> return an asynchronous update, as soon as something has changed
        if (hash.isEmpty())
            ResponseGenerator.getAsyncUpdate(longPollTimeout, sessionSpecificBroadcastManagers.get(sessionid));

        // A hash was provided, or we want to provoke a hash mismatch because no hash (not even an empty hash) was provided
        return ResponseGenerator.getHashBasedUpdate(longPollTimeout, sessionSpecificBroadcastManagers.get(sessionid), hash);
    }

    /**
     * Handles a join request of a user for an existing, open session. "PUT" is favoured over "POST" on the super
     * collection, because the client knows the id of the resource to be created.
     *
     * @return
     */
    @PreAuthorize("hasAnyAuthority('ROLE_PLAYER','ROLE_ADMIN')")
    @PutMapping("/api/sessions/{sessionid}/players/{player}")
    public ResponseEntity joinSession(@PathVariable long sessionid, @PathVariable String player, Principal principal, @RequestParam(required = false) String location) {

        // Reject if registration occurs on behalf of someone else
        if (!player.equals(principal.getName()))
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Session can not be joined on behalf of " +
                    "someone else.");

        // Reject if session id does not exist
        if (!sessions.isExistent(sessionid))
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Session can not be joined. Not a valid " +
                    "session-id.");

        // Reject if player is already registered for this session
        Session session = sessions.getSessionById(sessionid);
        if (session.getPlayers().contains(player))
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Session can not be joined. Player is " +
                    "already registered for this session.");

        // Reject if session is already full
        if (session.isFull())
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Session can not be joined. Session is " +
                    "already full.");

        // In case of a P2P game, verify a location was provided, register it.
        if (sessions.getSessionById(sessionid).getGameParameters().isPhantom()) {
            if (location == null || location.trim().isEmpty())
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Session for P2P game can not be created without providing client location.");
            if (!LocationValidator.isValidClientLocation(location))
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Provided client location is not a valid IP.");
        }
        // Reject locations if the associated game is not in p2p mode.
        else if (!(location == null || location.isEmpty()))
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Setting a client location is not allowed for non p2p games.");

        // Looks good. Let the player join the session, and notify all subscribers about update.
        session.addPlayer(player);

        // In case the session runs in phantom/p2p mode, attach the provided player location to the session
        if (location != null && !location.isEmpty())
            try {
                session.addPlayerLocation(player, location);
            } catch (SessionException se) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Unable to attach provided creator location to session.");
            }

        // Update registered subscribers
        sessionBroadcastManager.touch();
        sessionSpecificBroadcastManagers.get(sessionid).touch();
        return ResponseEntity.status(HttpStatus.OK).body(null);
    }

    @PreAuthorize("hasAnyAuthority('ROLE_PLAYER','ROLE_ADMIN')")
    @DeleteMapping("/api/sessions/{sessionid}/players/{player}")
    public ResponseEntity leaveSession(@PathVariable long sessionid, @PathVariable String player, Principal principal) {

        // Reject if un-registration occurs on behalf of someone else
        if (!player.equals(principal.getName()))
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Session can not be left on behalf of " +
                    "someone else.");

        // Reject if session id does not exist
        if (!sessions.isExistent(sessionid))
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Session can not be left. Not a valid " +
                    "session-id.");

        // Reject if it is the creator who wants to leave the session
        Session session = sessions.getSessionById(sessionid);
        if (session.getCreator().equals(player))
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Creator is not allowed to leave the " +
                    "session.");

        // Reject if not registered player of the session
        if (!session.getPlayers().contains(player))
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Session can not be left. Player not " +
                    "registered to the session.");

        // Reject if the session has already been launched
        if (session.isLaunched())
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Session can not be left. Game has already " +
                    "been launched.");

        // Looks good, remove the player form the session.
        session.removePlayer(player);
        sessionBroadcastManager.touch();
        sessionSpecificBroadcastManagers.get(sessionid).touch();
        return ResponseEntity.status(HttpStatus.OK).body(null);
    }

    /**
     * Launch a previously created session.
     */
    @PreAuthorize("hasAnyAuthority('ROLE_PLAYER','ROLE_ADMIN')")
    @PostMapping("/api/sessions/{sessionid}")
    public ResponseEntity launchSession(@PathVariable long sessionid, Principal principal) throws RegistryException {
        // Reject if session id does not exist
        if (!sessions.isExistent(sessionid))
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Session can not be launched. Not a valid " +
                    "session-id.");

        // Reject if launch occurs on behalf of someone else other than the creator
        Session session = sessions.getSessionById(sessionid);
        if (!principal.getName().equals(session.getCreator()))
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Session can not be launched on behalf of " +
                    "someone else.");

        // Reject if there are not yet enough players
        if (session.getPlayers().size() < session.getGameParameters().getMinSessionPlayers())
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Session can not be launched. Not enough " +
                    "players joined.");

        // Reject if the session has already been launched
        if (session.isLaunched())
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Session can not be launched. Game has " +
                    "already been launched.");

        // looks good
        // mark session as launched
        session.markAsLaunched();

        // notify registered game server that session has been launched (unless this is a phantom/p2p server)
        if (!gameServers.getGameServerParameters(session.getGameName()).isPhantom())
            notifyGameLaunch(sessionid, session.getGameName(), session);

        // update registered ASYNC clients
        sessionBroadcastManager.touch();
        sessionSpecificBroadcastManagers.get(sessionid).touch();
        return ResponseEntity.status(HttpStatus.OK).body(null);
    }

    /**
     * Helper method to send an HTTP request to the registered game service at the specified endpoint, to create the
     * game.
     *
     * @param sessionid
     */
    private void notifyGameLaunch(long sessionid, String gamename, Session session) throws RegistryException {

        logger.info("Notifying associated game service about session start.");

        // Reject launch notification if game-service was registered in phantom (p2p) mode.
        if (gameServers.getGameServerParameters(gamename).getLocation().isEmpty()) {
            String message = "Game-service can not be notified about session stall, because the service " +
                    "was registered in P2P mode.";
            logger.error(message);
            throw new RegistryException(message);
        }

        // Build and send REST request...
        StringBuilder urlBuilder = new StringBuilder("");
        urlBuilder.append(gameServers.getGameServerParameters(gamename).getLocation());
        urlBuilder.append(apiGamesUrl);
        urlBuilder.append(sessionid);
        logger.info("Session start request resource location: "+ urlBuilder.toString());

        LinkedList<PlayerInfo> players = new LinkedList<>();
        for (String player : session.getPlayers()) {
            players.add(new PlayerInfo(player, playerRepository.findById(player).get().getPreferredColour()));
        }
        LauncherInfo launcherInfo = new LauncherInfo(gamename, players, session.getCreator(), session.getSavegameid());
	Unirest.config().verifySsl(false);
        Unirest.put(urlBuilder.toString()).header("Content-Type", "application/json; charset=utf-8")
                .body(launcherInfo).asString();

        logger.info("Game service notified about session start.");
    }

    /**
     * Creates a random session ID that is not yet in use.
     */
    private long generateUniqueSessionId() {
        long randomSessionId = Math.abs(new Random().nextLong());
        while (sessions.isExistent(randomSessionId)) {
            randomSessionId = Math.abs(new Random().nextLong());
        }
        return randomSessionId;
    }

    /**
     * Synchronous endpoint, for clients to check whether BGP is up and running.
     *
     * @return The String: "online". No need to implement a negative answer, for a server that is down can not reply.
     */
    @GetMapping("/api/online")
    public String online() {
        long playerAmount = playerRepository.count();
        return "Lobby Service is happily serving " + playerAmount + " users.";
    }

    /**
     * Removes all sessions linked to a specific game time, whether they are launched or not. In case of launched
     * sessions, the corresponding game-server is notified, by a DELETE request.
     *
     * @param game as the name of the registered gameserver.
     */
    public void removeAllSessionsByGame(String game) throws RegistryException {
        for (long sessionid : sessions.getAllSessionsByGame(game)) {

            // If the game is already running, notify the corresponding game server that the sessions have been stalled.
            if (sessions.getSessionById(sessionid).isLaunched() && !gameServers.getGameServerParameters(game).isPhantom())
                notifyGameServerAboutDeletion(sessionid, game);

            // Delete the session and make sure the attached BCMs are unblocked.
            deleteSessionAndNotifyListeners(sessionid);
        }
    }

    /**
     * Removes a player form all sessions. Makes sure affected sessions are either deleted (player was creator or
     * session is already launched) and that the corresponding game-server is notified in case the session was already
     * launched.
     *
     * @param playername
     */
    public void removePlayerFromAllSessions(String playername) throws RegistryException {
        removeAllSessionsByCreator(playername);
        removeNonCreatorFromAllSessions(playername);
    }

    /**
     * Removes all sessions created by a specific player, whether they are launched or not. In case of launched
     * sessions, the corresponding game-server is notified, by a DELETE request.
     *
     * @param creatorname as the name of the potential session creator, whose sessions shall be removed.
     */
    private void removeAllSessionsByCreator(String creatorname) throws RegistryException {
        Collection<Long> sessionsByCreator = sessions.getAllSessionsByCreator(creatorname);
        for (long sessionId : sessionsByCreator) {
            if (sessions.getSessionById(sessionId).isLaunched() && !gameServers.getGameServerParameters(sessions.getSessionById(sessionId).getGameName()).isPhantom())
                notifyGameServerAboutDeletion(sessionId, sessions.getSessionById(sessionId).getGameName());
            deleteSessionAndNotifyListeners(sessionId);
        }
    }

    /**
     * Removes a non-creator player from all sessions. In case of a launched session, the corresponding game-server is
     * notified by a DELETE request.
     *
     * @param playerName as the name of the player whose sessions shall be removed (if launched) or updated (if note yet
     *                   launched.)
     */
    private void removeNonCreatorFromAllSessions(String playerName) throws RegistryException {
        Collection<Long> sessionsByCreator = sessions.getAllSessionsWithPlayer(playerName);
        for (long sessionId : sessionsByCreator) {
            if (sessions.getSessionById(sessionId).isLaunched())
                notifyGameServerAboutDeletion(sessionId, sessions.getSessionById(sessionId).getGameName());
            deleteSessionAndNotifyListeners(sessionId);
        }
    }

    /**
     * Sends a DELETE request to an associated gameserver, to kill a running game. This can happen due to numerous
     * reasons: The admin in charge of the gameserver was deleted. The gameserver was unregistered. A participator of
     * the game was deleted. Gameservers can not be notified in case they were launched in phantom (P2P) mode.
     *
     * @param sessionid as the unique id of the game in question.
     * @param gamename  as the name of the associated game-service.
     * @throws RegistryException
     */
    private void notifyGameServerAboutDeletion(long sessionid, String gamename) throws RegistryException {

        // Reject launch notification if game-service was registered in phantom (p2p) mode.
        if (gameServers.getGameServerParameters(gamename).getLocation().isEmpty())
            throw new RegistryException("Game-service can not be notified about session stall, because the service " +
                    "was registered in P2P mode.");

        // Build and send REST request...
        StringBuilder urlBuilder = new StringBuilder("");
        urlBuilder.append(gameServers.getGameServerParameters(gamename).getLocation());
        urlBuilder.append(apiGamesUrl);
        urlBuilder.append(sessionid);
        Unirest.delete(urlBuilder.toString()).header("Content-Type", "application/json; charset=utf-8").asString();
    }

    /**
     * Iterates over all sessions and deletes the sessions that are unlaunched AND originate the provided savegameid.
     * Concerned BCMs are unblocked, as well as the master BCM, in case there was at least on affected session.
     *
     * @param savegameid  as the id of the savegame. Ids are only guaranteed unique per gameserver, therefore the
     *                    gameserver has to match, too.
     * @param gameservice as the name of the gamerserver that defined the sessionid context.
     */
    public void removeAllBySavegame(String savegameid, String gameservice) {

        Map<Long, Session> affectedSessions = sessions.getAllUnlaunchedSessionsBySavegame(savegameid, gameservice);

        if (!affectedSessions.isEmpty())
            for (Entry<Long, Session> sessionEntry : affectedSessions.entrySet()) {
                String sessionGameservice = sessionEntry.getValue().getGameName();
                String sessionSavegameId = sessionEntry.getValue().getSavegameid();
                if (sessionGameservice.equals(gameservice) && sessionSavegameId.equals(savegameid)) {

                    // Remove session and notify BCM
                    Long sessionId = sessionEntry.getKey();
                    sessions.removeSession(sessionId);
                    sessionSpecificBroadcastManagers.get(sessionId).terminate();
                }

                // update global session BCM
                sessionBroadcastManager.touch();
            }
    }
}
