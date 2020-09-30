package eu.kartoffelquadrat.ls.accountmanager.controller;

/**
 * Simpe bean to encode a colour string when a preferred colour update is transferred from client to server as a
 * json-encoded string.
 */
public class ColourForm {

    String colour;

    public ColourForm(String colour) {
        this.colour = colour;
    }

    public ColourForm() {
    }

    public String getColour() {
        return colour;
    }

    public void setColour(String colour) {
        this.colour = colour;
    }
}
