package eu.kartoffelquadrat.ls.accountmanager.controller;

import eu.kartoffelquadrat.ls.accountmanager.model.Role;

import java.util.regex.Pattern;

/**
 * Simple bean to encapsulate the data transferred from client to backend upon registration of a new user.
 *
 * @author Maximilian Schiedermeier, August 2020
 */
public class AccountForm {

    String name;
    String password;
    String preferredColour;
    Role role;

    public AccountForm(String name, String password, String preferredColour, Role role) {
        this.name = name;
        this.password = password;
        this.preferredColour = preferredColour;
        this.role = role;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getPreferredColour() {
        return preferredColour;
    }

    public void setPreferredColour(String preferredColour) {
        this.preferredColour = preferredColour;
    }

    public Role getRole() {
        return role;
    }

    public void setRole(Role role) {
        this.role = role;
    }

    /**
     * Semantic validation of the bean content. Invoked when new game is registered.
     *
     * Password policy adapted from here:
     * https://www.ocpsoft.org/tutorials/regular-expressions/password-regular-expression/
     * At least one digit [0-9]
     * At least one lowercase character [a-z]
     * At least one uppercase character [A-Z]
     * 8-32 characters long
     */
    public void validate() throws AccountException {
        StringBuilder problems = new StringBuilder("");

        if (name.trim().isEmpty())
            problems.append("Name must not be only whitespaces.");
        if (!validatePasswordString(password))
            problems.append("Password does not comply to password policy. ");
        if (!validateColourString(preferredColour))
            problems.append("Colour is not a valid hex-rgb string, e.g. 3A6C42. ");
        if (!problems.toString().isEmpty())
            throw new AccountException(problems.toString());
    }

    public static boolean validatePasswordString(String password)
    {
        return Pattern.compile("(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*[^A-Za-z0-9]).{8,32}").matcher(password).find();
    }

    public static boolean validateColourString(String colourString)
    {
        return Pattern.compile("(?:[0-9A-F]{6})").matcher(colourString).find();
    }
}
