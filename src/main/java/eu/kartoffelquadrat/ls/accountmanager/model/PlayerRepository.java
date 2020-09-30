package eu.kartoffelquadrat.ls.accountmanager.model;

import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Spring automatically implements this repository interface in a bean that has the same name (with a change in the
 * case it is called "playerRepository")
 */
public interface PlayerRepository extends JpaRepository<Player, String> {

    // Retrieve all players with a specific name
//    @Query(value = "SELECT id FROM player WHERE name=?1", nativeQuery = true)
//    List<Player> findByName(String name);
}