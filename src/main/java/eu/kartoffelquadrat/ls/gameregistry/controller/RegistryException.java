package eu.kartoffelquadrat.ls.gameregistry.controller;

import org.slf4j.LoggerFactory;

public class RegistryException extends Exception {

    public RegistryException(String cause)
    {
        super(cause);
        LoggerFactory.getLogger(RegistryException.class).error(cause);
    }
}
