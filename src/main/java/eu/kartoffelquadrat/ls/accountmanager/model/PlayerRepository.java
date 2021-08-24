package eu.kartoffelquadrat.ls.accountmanager.model;

import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Spring automatically implements a corresponding DAO if this interface is provicec. Can be autowired as bean where access to players is needed.
 * Spring's data repository. Do not remove this interface!
 */
public interface PlayerRepository extends JpaRepository<Player, String> {

}