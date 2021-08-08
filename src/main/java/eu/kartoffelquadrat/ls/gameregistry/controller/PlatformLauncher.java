package eu.kartoffelquadrat.ls.gameregistry.controller;

import eu.kartoffelquadrat.ls.accountmanager.controller.AccountController;
import eu.kartoffelquadrat.ls.accountmanager.controller.AccountForm;
import eu.kartoffelquadrat.ls.accountmanager.model.Player;
import eu.kartoffelquadrat.ls.accountmanager.model.Role;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;
import org.springframework.context.ApplicationContext;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

/**
 * Powers up the Lobby Service
 *
 * @author Maximilian Schiedermeier, August 2020
 */
@SpringBootApplication(scanBasePackages = {"eu.kartoffelquadrat.ls"})
@EnableJpaRepositories("eu.kartoffelquadrat.ls")
@EntityScan("eu.kartoffelquadrat.ls")
public class PlatformLauncher extends SpringBootServletInitializer {

    public static void main(String[] args) {

        System.out.println("Starting up the Lobby Service...");

        // Power up spring boot
        ApplicationContext context = SpringApplication.run(PlatformLauncher.class, args);

        // Print welcome message
        System.out.println("Lobby Service up and running. Verification echo available at \"/api/online\".");
    }
}
