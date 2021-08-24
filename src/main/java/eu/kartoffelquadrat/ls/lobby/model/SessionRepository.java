package eu.kartoffelquadrat.ls.lobby.model;

import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Unlike the player repository, spring here cannot automatically implements a corresponding DAO. Reasion is that spring does not know how to implement the required methods of the broadcastcontent interface. Therefore, in this case we have to manually provide a repository implementation: "SessionRepositoryImplementation"
 * TODO: figure out how to also implement broadcastcontent interface methods in springs auto-generated DAO-bean.
 * See: https://thorben-janssen.com/composite-repositories-spring-data-jpa/
 *
 * Used by: Savegame-Controller, Session-Controller
 */
public interface SessionRepository extends JpaRepository<Session, Long>, BroadcastableSessionRepository {

}