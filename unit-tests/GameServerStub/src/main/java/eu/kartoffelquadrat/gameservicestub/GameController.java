/**
 * OAuth2 secured version of the timeservice. Following this tutorial: http://websystique.com/spring-security/secure-spring-rest-api-using-oauth2/
 *
 * @Author: Maximilian Schiedermeier
 * @Date: April 2019
 */
package eu.kartoffelquadrat.gameservicestub;

import org.springframework.web.bind.annotation.*;

import java.util.*;
import com.google.gson.Gson;

/***
 * This controller tells the time via a REST interface.
 */
@RestController
public class GameController {

    private final String LOG_START = "\u001B[38;5;184m";
    private final String LOG_END = "\u001B[m";




    // Collection to remember which games are currently active.
    Collection<Long> games = new LinkedList<>();

    /**
     * REST endpoint to start a new game (originating a launched session).
     *
     * @param gameid       as the BGP generated ID of the game.
     * @param launcherInfo as all additional information required to launch the game (players, colors, seating-order,
     *                     start player.)
     */
    @PutMapping(value = "/api/games/{gameid}", consumes = "application/json; charset=utf-8")
    public void startGame(@PathVariable long gameid, @RequestBody LauncherInfo launcherInfo) {

        System.out.println(LOG_START + "Received request to start a new game (" + gameid + ") with parameters: " + new Gson().toJson(launcherInfo) + LOG_END);
        if(launcherInfo == null || launcherInfo.gameServer == null) {
            System.out.println(LOG_START + "REJECTED! Request body has bad format." + LOG_END);
        return;}
        if (launcherInfo.gameServer.equals(Launcher.GAME_SERVICE_NAME))
            System.out.println(LOG_START + "REJECTED! Game service does not match." + LOG_END);
        else
            games.add(gameid);
    }

    /**
     * REST endpoint to delete a running game.
     *
     * @param gameid as the id of the game to delete.
     */
    @DeleteMapping("/api/games/{gameid}")
    public void stopGame(@PathVariable long gameid) {
        System.out.println(LOG_START + "Received request to stop game (" + gameid + ")." + LOG_END);
        if (!games.contains(gameid))
            System.out.println(LOG_START + "ERROR! No game with provided id is currently running." + LOG_END);
    }

    /**
     * WEB-UI endpoint to retrieve a webpage that then dynamically loads game data from other game-server endpoints.
     *
     * @param gameid as the id of the game to display.
     * @return HTML code of a webclient.
     */
    @GetMapping("/ui/games/{gameid}")
    public String getGameWebUi(@PathVariable long gameid) {
        System.out.println(LOG_START + "Received request for game webui (" + gameid + ")."+LOG_END);
        if (!games.contains(gameid))
            System.out.println(LOG_START + "ERROR! No game with provided id is currently running."+LOG_END);
        return "---Webpage for game " + gameid + " here---";
    }

    /**
     * Debug endpoint. Can be accesses at: http://127.0.0.1:4243/FunnyDemoGameServer/online
     */
    @GetMapping("/online")
    public String getOnlineFlag() {
        return "Demo game server is happily running.";
    }
}
