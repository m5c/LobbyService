package eu.kartoffelquadrat.ls.accountmanager.controller;

/**
 * Generic error object that can be serialized to JSON and returned, to keep API return format
 * consistent.
 *
 * @author Maximilian Schiedermeier
 */
public class ErrorForm {
  private final String errorMessage;

  public ErrorForm(String errorMessage) {
    this.errorMessage = errorMessage;
  }

  public String getErrorMessage() {
    return errorMessage;
  }
}
