{
    "createdAt": "2020-09-16T12:18:45.076Z",
    "kind": "ARC#ProjectExport",
    "projects": [
        {
            "key": "2a29af38-8220-4a55-b935-2a2ccfcfed3d",
            "kind": "ARC#ProjectData",
            "name": "BGP-Gameservices",
            "order": 0,
            "requests": [
                "3dfecdb1-9956-47ec-8bbd-1a989282a13d",
                "aa63f54e-38a0-45b1-b702-6a835ff7ea82",
                "cb11ffc6-df00-4c06-a195-b330fb0543c8",
                "cc591265-6504-4383-89c5-1c22ce5d6f46"
            ],
            "updated": 1600257696395
        }
    ],
    "requests": [
        {
            "auth": {
                "password": "bgp-client-pw",
                "username": "bgp-client-name"
            },
            "authType": "basic",
            "created": 1591452450261,
            "description": "",
            "headers": "Content-Type: application/json",
            "key": "18140a29-0483-4bb4-8cd0-a2fb343303d5",
            "kind": "ARC#RequestData",
            "method": "PUT",
            "name": "AddUser",
            "payload": "{\n    \"name\": \"foobar\",\n    \"password\": \"abc_123ABC123\",\n    \"preferredColour\": \"01FFFF\",\n    \"role\": \"ROLE_PLAYER\"\n}",
            "projects": [
                "73ed5306-e268-4348-ae5a-096591e7e246"
            ],
            "requestActions": {
                "variables": [
                    {
                        "enabled": false,
                        "value": "",
                        "variable": "myVar"
                    }
                ]
            },
            "type": "saved",
            "updated": 1600247832351,
            "url": "http://127.0.0.1:4242/api/users/foobar?access_token=ejTVAURmel1SK960juXqE3gos9c="
        },
        {
            "auth": {
                "password": "bgp-client-pw",
                "username": "bgp-client-name"
            },
            "authType": "basic",
            "created": 1591452450261,
            "description": "",
            "headers": "",
            "key": "35ab6bde-3530-4e57-aff5-f31e0464c94b",
            "kind": "ARC#RequestData",
            "method": "GET",
            "name": "GetColour",
            "payload": "{\n  \"colour\": \"DECAFF\"\n}",
            "projects": [
                "73ed5306-e268-4348-ae5a-096591e7e246"
            ],
            "requestActions": {
                "variables": [
                    {
                        "enabled": false,
                        "value": "",
                        "variable": "myVar"
                    }
                ]
            },
            "type": "saved",
            "updated": 1600248042381,
            "url": "http://127.0.0.1:4242/api/users/foobar/colour?access_token=ejTVAURmel1SK960juXqE3gos9c="
        },
        {
            "auth": {
                "password": "bgp-client-pw",
                "username": "bgp-client-name"
            },
            "authType": "basic",
            "created": 1591452450261,
            "description": "",
            "headers": "Content-Type: application/json",
            "key": "3981f1ab-ebcd-47ed-bc06-3f383fbc98f5",
            "kind": "ARC#RequestData",
            "method": "POST",
            "name": "UpdatePassword",
            "payload": "{\n    \"nextPassword\": \"abc123_ABC123\",\n    \"oldPassword\": \"abc_123ABC123\"\n}",
            "projects": [
                "73ed5306-e268-4348-ae5a-096591e7e246"
            ],
            "requestActions": {
                "variables": [
                    {
                        "enabled": false,
                        "value": "",
                        "variable": "myVar"
                    }
                ]
            },
            "type": "saved",
            "updated": 1600247940768,
            "url": "http://127.0.0.1:4242/api/users/foobar/password?access_token=ejTVAURmel1SK960juXqE3gos9c="
        },
        {
            "auth": {
                "password": "bgp-client-pw",
                "username": "bgp-client-name"
            },
            "authType": "basic",
            "created": 1591452450261,
            "description": "",
            "headers": "",
            "key": "3dfecdb1-9956-47ec-8bbd-1a989282a13d",
            "kind": "ARC#RequestData",
            "method": "DELETE",
            "name": "UnregisterGameservice",
            "payload": "",
            "projects": [
                "2a29af38-8220-4a55-b935-2a2ccfcfed3d"
            ],
            "requestActions": {
                "variables": [
                    {
                        "enabled": false,
                        "value": "",
                        "variable": "myVar"
                    }
                ]
            },
            "type": "saved",
            "updated": 1600258252949,
            "url": "http://127.0.0.1:4242/api/gameservices/DummyGame1?access_token=%2BU28OLgzRSVk56C/OMs2aQhvmgQ="
        },
        {
            "auth": {
                "password": "bgp-client-pw",
                "username": "bgp-client-name"
            },
            "authType": "basic",
            "created": 1591452450261,
            "description": "",
            "headers": "",
            "key": "59deb7ef-836c-4648-8659-290434cc2256",
            "kind": "ARC#RequestData",
            "method": "DELETE",
            "name": "DeleteUser",
            "payload": "{\n  \"colour\": \"DECAFF\"\n}",
            "projects": [
                "73ed5306-e268-4348-ae5a-096591e7e246"
            ],
            "requestActions": {
                "variables": [
                    {
                        "enabled": false,
                        "value": "",
                        "variable": "myVar"
                    }
                ]
            },
            "type": "saved",
            "updated": 1600248071356,
            "url": "http://127.0.0.1:4242/api/users/foobar?access_token=ejTVAURmel1SK960juXqE3gos9c="
        },
        {
            "auth": {
                "password": "bgp-client-pw",
                "username": "bgp-client-name"
            },
            "authType": "basic",
            "created": 1591452450261,
            "description": "",
            "headers": "",
            "key": "6bec9afb-6397-44af-8f99-33dc2dc81a65",
            "kind": "ARC#RequestData",
            "method": "GET",
            "name": "GetAllUsers",
            "payload": "user_oauth_approval=true&_csrf=19beb2db-3807-4dd5-9f64-6c733462281b&authorize=true",
            "projects": [
                "73ed5306-e268-4348-ae5a-096591e7e246"
            ],
            "requestActions": {
                "variables": [
                    {
                        "enabled": false,
                        "value": "",
                        "variable": "myVar"
                    }
                ]
            },
            "type": "saved",
            "updated": 1600247657864,
            "url": "http://127.0.0.1:4242/api/users?access_token=ejTVAURmel1SK960juXqE3gos9c="
        },
        {
            "auth": {
                "password": "bgp-client-pw",
                "username": "bgp-client-name"
            },
            "authType": "basic",
            "created": 1591452450261,
            "description": "",
            "headers": "",
            "key": "81479ef4-e473-4f9c-9ed0-6b67077454ff",
            "kind": "ARC#RequestData",
            "method": "POST",
            "name": "PutToken (Refresh)",
            "payload": "user_oauth_approval=true&_csrf=19beb2db-3807-4dd5-9f64-6c733462281b&authorize=true",
            "projects": [
                "2e93e630-dde9-4fa8-98a0-0015f0d818e2"
            ],
            "requestActions": {
                "variables": [
                    {
                        "enabled": false,
                        "value": "",
                        "variable": "myVar"
                    }
                ]
            },
            "type": "saved",
            "updated": 1600246598859,
            "url": "http://127.0.0.1:4242/oauth/token?grant_type=refresh_token&refresh_token=vOGG5bL9ariJbthJb8TmzFFPSAE="
        },
        {
            "auth": {
                "password": "bgp-client-pw",
                "username": "bgp-client-name"
            },
            "authType": "basic",
            "created": 1591452450261,
            "description": "",
            "headers": "",
            "key": "88b50b30-aacb-4afa-9b4b-be670ee7e51a",
            "kind": "ARC#RequestData",
            "method": "POST",
            "name": "PutToken",
            "payload": "user_oauth_approval=true&_csrf=19beb2db-3807-4dd5-9f64-6c733462281b&authorize=true",
            "projects": [
                "2e93e630-dde9-4fa8-98a0-0015f0d818e2"
            ],
            "requestActions": {
                "variables": [
                    {
                        "enabled": false,
                        "value": "",
                        "variable": "myVar"
                    }
                ]
            },
            "type": "saved",
            "updated": 1600246393906,
            "url": "http://127.0.0.1:4242/oauth/token?grant_type=password&username=maex&password=abc123"
        },
        {
            "auth": {
                "password": "bgp-client-pw",
                "username": "bgp-client-name"
            },
            "authType": "basic",
            "created": 1600248073163,
            "description": "",
            "headers": "",
            "key": "8e929185-d48d-4999-964a-b657b69dea15",
            "kind": "ARC#RequestData",
            "method": "GET",
            "name": "Online",
            "payload": "{\n  \"colour\": \"DECAFF\"\n}",
            "projects": [
                "c99078e1-175a-4c8c-beda-abc515128640"
            ],
            "requestActions": {
                "variables": [
                    {
                        "enabled": false,
                        "value": "",
                        "variable": "myVar"
                    }
                ]
            },
            "type": "saved",
            "updated": 1600249035721,
            "url": "http://127.0.0.1:4242/api/online"
        },
        {
            "auth": null,
            "authType": null,
            "created": 1600246786961,
            "description": "",
            "headers": "",
            "key": "a209afec-9992-4a9d-a606-7a42d01869b7",
            "kind": "ARC#RequestData",
            "method": "DELETE",
            "name": "RevokeToken",
            "payload": "",
            "projects": [
                "2e93e630-dde9-4fa8-98a0-0015f0d818e2"
            ],
            "type": "saved",
            "updated": 1600246786961,
            "url": "http://127.0.0.1:4242/oauth/active?access_token=zB4ZN5HXm80VDfs9X9Jw5GtBBlk="
        },
        {
            "auth": null,
            "authType": null,
            "created": 1600246726654,
            "description": "",
            "headers": "",
            "key": "a52f2236-9388-460a-b09e-57246306511c",
            "kind": "ARC#RequestData",
            "method": "GET",
            "name": "GetUsername",
            "payload": "",
            "projects": [
                "2e93e630-dde9-4fa8-98a0-0015f0d818e2"
            ],
            "type": "saved",
            "updated": 1600246726654,
            "url": "http://127.0.0.1:4242/oauth/username?access_token=zB4ZN5HXm80VDfs9X9Jw5GtBBlk="
        },
        {
            "auth": null,
            "authType": null,
            "created": 1600246696472,
            "description": "",
            "headers": "",
            "key": "a60fb41f-5a3e-4e1c-b24f-11fa89927ba3",
            "kind": "ARC#RequestData",
            "method": "GET",
            "name": "GetRole",
            "payload": "",
            "projects": [
                "2e93e630-dde9-4fa8-98a0-0015f0d818e2"
            ],
            "type": "saved",
            "updated": 1600246696472,
            "url": "http://127.0.0.1:4242/oauth/role?access_token=zB4ZN5HXm80VDfs9X9Jw5GtBBlk="
        },
        {
            "auth": {
                "password": "bgp-client-pw",
                "username": "bgp-client-name"
            },
            "authType": "basic",
            "created": 1591452450261,
            "description": "",
            "headers": "",
            "key": "aa63f54e-38a0-45b1-b702-6a835ff7ea82",
            "kind": "ARC#RequestData",
            "method": "GET",
            "name": "GetGameservices",
            "payload": "user_oauth_approval=true&_csrf=19beb2db-3807-4dd5-9f64-6c733462281b&authorize=true",
            "projects": [
                "2a29af38-8220-4a55-b935-2a2ccfcfed3d"
            ],
            "requestActions": {
                "variables": [
                    {
                        "enabled": false,
                        "value": "",
                        "variable": "myVar"
                    }
                ]
            },
            "type": "saved",
            "updated": 1600257889075,
            "url": "http://127.0.0.1:4242/api/gameservices"
        },
        {
            "auth": {
                "password": "bgp-client-pw",
                "username": "bgp-client-name"
            },
            "authType": "basic",
            "created": 1591452450261,
            "description": "",
            "headers": "Content-Type: application/json",
            "key": "cb11ffc6-df00-4c06-a195-b330fb0543c8",
            "kind": "ARC#RequestData",
            "method": "PUT",
            "name": "RegisterGameservice",
            "payload": "{\n    \"location\": \"http://127.0.0.1:4243/DummyGameService\",\n    \"maxSessionPlayers\": \"5\",\n    \"minSessionPlayers\": \"3\",\n    \"name\": \"DummyGame2\",\n    \"webSupport\": \"true\"\n}",
            "projects": [
                "2a29af38-8220-4a55-b935-2a2ccfcfed3d"
            ],
            "requestActions": {
                "variables": [
                    {
                        "enabled": false,
                        "value": "",
                        "variable": "myVar"
                    }
                ]
            },
            "type": "saved",
            "updated": 1600258098050,
            "url": "http://127.0.0.1:4242/api/gameservices/DummyGame2?access_token=%2BU28OLgzRSVk56C/OMs2aQhvmgQ="
        },
        {
            "auth": {
                "password": "bgp-client-pw",
                "username": "bgp-client-name"
            },
            "authType": "basic",
            "created": 1591452450261,
            "description": "",
            "headers": "",
            "key": "cc591265-6504-4383-89c5-1c22ce5d6f46",
            "kind": "ARC#RequestData",
            "method": "GET",
            "name": "GetGameservice",
            "payload": "user_oauth_approval=true&_csrf=19beb2db-3807-4dd5-9f64-6c733462281b&authorize=true",
            "projects": [
                "2a29af38-8220-4a55-b935-2a2ccfcfed3d"
            ],
            "requestActions": {
                "variables": [
                    {
                        "enabled": false,
                        "value": "",
                        "variable": "myVar"
                    }
                ]
            },
            "type": "saved",
            "updated": 1600257962297,
            "url": "http://127.0.0.1:4242/api/gameservices/DummyGame1"
        },
        {
            "auth": {
                "password": "bgp-client-pw",
                "username": "bgp-client-name"
            },
            "authType": "basic",
            "created": 1591452450261,
            "description": "",
            "headers": "",
            "key": "de08b5e0-30cf-41fa-a613-0de9002bdd93",
            "kind": "ARC#RequestData",
            "method": "GET",
            "name": "GetUser",
            "payload": "user_oauth_approval=true&_csrf=19beb2db-3807-4dd5-9f64-6c733462281b&authorize=true",
            "projects": [
                "73ed5306-e268-4348-ae5a-096591e7e246"
            ],
            "requestActions": {
                "variables": [
                    {
                        "enabled": false,
                        "value": "",
                        "variable": "myVar"
                    }
                ]
            },
            "type": "saved",
            "updated": 1600247719260,
            "url": "http://127.0.0.1:4242/api/users/maex?access_token=ejTVAURmel1SK960juXqE3gos9c="
        },
        {
            "auth": {
                "password": "bgp-client-pw",
                "username": "bgp-client-name"
            },
            "authType": "basic",
            "created": 1591452450261,
            "description": "",
            "headers": "Content-Type: application/json",
            "key": "f76ec770-818c-4113-9987-dcae236edeaf",
            "kind": "ARC#RequestData",
            "method": "POST",
            "name": "UpdateColour",
            "payload": "{\n  \"colour\": \"DECAFF\"\n}",
            "projects": [
                "73ed5306-e268-4348-ae5a-096591e7e246"
            ],
            "requestActions": {
                "variables": [
                    {
                        "enabled": false,
                        "value": "",
                        "variable": "myVar"
                    }
                ]
            },
            "type": "saved",
            "updated": 1600248005368,
            "url": "http://127.0.0.1:4242/api/users/foobar/colour?access_token=ejTVAURmel1SK960juXqE3gos9c="
        }
    ],
    "version": "15.0.7"
}
