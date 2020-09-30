package eu.kartoffelquadrat.ls.gameregistry.controller;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

/**
 * Powers up the Lobby Service
 *
 * @author Maximilian Schiedermeier, August 2020
 */
@SpringBootApplication(scanBasePackages = {"eu.kartoffelquadrat.ls"})
@EnableJpaRepositories("eu.kartoffelquadrat.ls")
@EntityScan("eu.kartoffelquadrat.ls")
public class PlatformLauncher {

    public static void main(String[] args) {

        System.out.println("Starting up the BoardGamePlatform...");

        // Power up spring boot
        SpringApplication.run(PlatformLauncher.class, args);

        // Print welcome message
        System.out.println("BGP up and running. Verification echo available at: http://127.0.0.1:4242/api/online");
    }
}
