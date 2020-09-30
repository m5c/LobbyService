package eu.kartoffelquadrat.gameservicestub;

/**
 * Encodes minimal information required for launch instructions.
 */
public class PlayerInfo {

    String name;
    String preferredColour;

    public PlayerInfo(String name, String preferredColour) {
        this.name = name;
        this.preferredColour = preferredColour;
    }

    public PlayerInfo() {
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getPreferredColour() {
        return preferredColour;
    }

    public void setPreferredColour(String preferredColour) {
        this.preferredColour = preferredColour;
    }

    @Override
    public String toString() {
        return "Name: " + name + "- PreferredColour: " + preferredColour;
    }
}
