# Lobby Service Unit Tests

This directory contains scripted unit tests, to test the [REST API](../markdown/api.md) exposed by the Lobby Service.  
The remainder of this page is only relevant for Lobby-Service developers.

## About

 * The unit tests cover 100% of the [REST API](../markdown/api.md) defined in the API specification.
 * Testing is divided into multiple sub-sequences which can also be invoked manually, for more targeted testing.
   * Manual testing of sub-sequences may require the manual registration of a [stub game-service](GameServerStub)
   * ```cd``` into ```GameServerStub``` and power up the dummy game service with ```mvn spring-boot:run``` to log outbound messages.
   * For interactive verification set the ```INTERLEAVED``` variable, before calling a test-sequence: ```INTERLEAVED=true```. The subsequences will then stall whenever outbound messages need to be verified manually. Continue with the *Enter* key.

## Usage

 * Power up the lobby service, as described in the [build/deploy documentation](../markdown/build-deploy.md).  
 * Launch all unit tests with ```ls-units-all.sh```. This will sequentially iterate through all individual test sequences, targeting specific API-tree parts.
 * The unit tests also require verification of outbound messages towards a stub game-service. If prompted for manual verification, compare the expected output to the intercepted communication (printed in yellow).

 > Note: Unit testing of a docker-compose setup is not supported, for the test cases also cover expected communication with game-hosts running on the host (not supported by docker compose on OSX).
