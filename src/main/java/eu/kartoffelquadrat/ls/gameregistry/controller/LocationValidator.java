package eu.kartoffelquadrat.ls.gameregistry.controller;

import java.util.regex.Pattern;

/**
 * Static helper class to validate Strings for IP+port ranges / IP ranges.
 *
 * @author Maximilian Schiedermeier, September 2020
 */
public class LocationValidator {

    /**
     * Validates whether a provided string is a valid IP address oder docker identifier (lower case string over
     * alphabet [a-z]) plus (both cases) a port information.
     *
     * @param location the provided server location string
     * @return the validation result
     */
    public static boolean isValidGameServiceLocation(String location) {
        return Pattern.compile("((([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|" +
                "2[0-4][0-9]|25[0-5])|([a-z]+)):[0-9]+").matcher(location).find();
    }

    /**
     * Validates whether a provided string is a valid IP address.
     *
     * @param location the provided client location string
     * @return the validation result
     */
    public static boolean isValidClientLocation(String location) {
        return Pattern.compile("(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|" +
                "2[0-4][0-9]|25[0-5])").matcher(location).find();
    }
}
