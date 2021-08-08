package eu.kartoffelquadrat.ls.accountmanager.model;

import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Spring automatically implements this repository interface in a bean that has the same name (with a change in the
 * case it is called "playerRepository"). Therefore, do not remove this interface!
 */
public interface PlayerRepository extends JpaRepository<Player, String> {

}