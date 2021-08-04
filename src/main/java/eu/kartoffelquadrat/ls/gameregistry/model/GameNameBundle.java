package eu.kartoffelquadrat.ls.gameregistry.model;

/**
 * Simple bean that encapsulates reduced information for a specific game: how to identify the game and how to display
 * it's name.
 */
public class GameNameBundle {

    // Game name serves as unique identifier and should not contain characters that require escaping in URL-Encoding.
    private String name;

    // Display name can be anything and should emphasize human readability.
    private String displayName;

    public GameNameBundle(String name, String displayName) {
        this.name = name;
        this.displayName = displayName;
    }

    public String getName() {
        return name;
    }

    public String getDisplayName() {
        return displayName;
    }

    public void setName(String name) {
        this.name = name;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }
}
