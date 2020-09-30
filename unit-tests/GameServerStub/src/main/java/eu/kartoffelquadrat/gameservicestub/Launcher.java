/**
 * Launch this program with:
 * "mvn spring-boot:run"
 *
 * Then open a browser and visit:
 * "http://127.0.0.1:4243/FunnyDemoGameServer/online"
 *
 * Other endpoints as described in BGP documentation.
 *
 * @Author: Maximilian Schiedermeier
 * @Date: August 2020
 */
package eu.kartoffelquadrat.gameservicestub;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * This class powers up Spring and ensures the annotated controllers are detected.
 */
@SpringBootApplication
public class Launcher {

    public static final String GAME_SERVICE_NAME = "DummyService1";

    public static void main(String[] args) {
        SpringApplication.run(Launcher.class, args);
    }
}

