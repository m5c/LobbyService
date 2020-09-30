package eu.kartoffelquadrat.ls.accountmanager.controller;

/**
 * Transport bean to transport a JSON encoded password from client to server.
 *
 * @author Maximilian Schiedermeier, August 2020
 */
public class PasswordForm {

    private String oldPassword;
    private String nextPassword;

    public PasswordForm() {
    }

    public PasswordForm(String nextPassword, String oldPassword) {
        this.nextPassword = nextPassword;
    }

    public String getNextPassword() {
        return nextPassword;
    }

    public void setNextPassword(String nextPassword) {
        this.nextPassword = nextPassword;
    }

    public String getOldPassword() {
        return oldPassword;
    }

    public void setOldPassword(String oldPassword) {
        this.oldPassword = oldPassword;
    }
}
