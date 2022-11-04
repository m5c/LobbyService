USE ls;
DROP TABLE player;
CREATE TABLE player (name varchar(255) NOT NULL PRIMARY KEY, password varchar(255) NOT NULL, preferred_colour varchar(255) NOT NULL, role varchar(255) NOT NULL);
INSERT INTO player VALUES ('maex', '$2a$12$H4kY2m6c3L9qqm681wYWo.KO0AWTz18rf7UWjyL5VrJ/uBkD2jty2', 'FCBA03', 'ROLE_ADMIN');
INSERT INTO player VALUES ('linus', '$2a$12$H4kY2m6c3L9qqm681wYWo.KO0AWTz18rf7UWjyL5VrJ/uBkD2jty2', 'CAFFEE', 'ROLE_PLAYER');
INSERT INTO player VALUES ('khabiir', '$2a$12$H4kY2m6c3L9qqm681wYWo.KO0AWTz18rf7UWjyL5VrJ/uBkD2jty2', '0367FC', 'ROLE_PLAYER');
INSERT INTO player VALUES ('marianick', '$2a$12$H4kY2m6c3L9qqm681wYWo.KO0AWTz18rf7UWjyL5VrJ/uBkD2jty2', 'FC0356', 'ROLE_PLAYER');
INSERT INTO player VALUES ('xox', '$2a$12$i9TOyr9T04CKaoff7Tt9vuoIeH0zmuKj7KQ1O22Uk.h47WruSoTf.', 'FFFFFF', 'ROLE_SERVICE');
