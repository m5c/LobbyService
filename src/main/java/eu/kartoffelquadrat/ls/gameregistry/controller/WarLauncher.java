package eu.kartoffelquadrat.ls.gameregistry.controller;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

/**
 * Powers up the Lobby Service
 *
 * @author Maximilian Schiedermeier, August 2020
 */
@SpringBootApplication(scanBasePackages = {"eu.kartoffelquadrat.ls"})
@EnableJpaRepositories("eu.kartoffelquadrat.ls")
@EntityScan("eu.kartoffelquadrat.ls")
public class WarLauncher extends SpringBootServletInitializer {

    public static void main(String[] args) {

        System.out.println("Starting up the Lobby Service...");

        // Power up spring boot
        SpringApplication.run(PlatformLauncher.class, args);

        // Print welcome message
        System.out.println("Lobby Service war deployed. Verification echo available at /api/online");
    }
}
