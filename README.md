# CiviCRM Docker

Docker container for [CiviCRM buildkit](https://github.com/civicrm/civicrm-buildkit) that can be ran as an arbitrary (non-root) user. Based on [michaelmcandrew/civicrm-buildkit-docker](https://github.com/michaelmcandrew/civicrm-buildkit-docker), but focused more on hosting than development purposes.

Available also in Docker Hub: [secoresearch/civicrm](https://hub.docker.com/r/secoresearch/civicrm/).

## Build

`docker-compose build`

## Run

`docker-compose up -d`

Runs also a MySQL database container.

## Usage

Create a new CiviCRM installation (see [civibuild documentation](https://docs.civicrm.org/dev/en/latest/tools/civibuild/)):

`docker-compose exec -u buildkit civicrm civibuild create [BUILD_NAME] [PARAMETERS]`

Fix the file permissions so that the container can be ran as non-root user (however these creation steps need sudo privileges in the `civirm` container):

`docker-compose exec -u buildkit civicrm bash -c "sudo chgrp -R 0 /buildkit && sudo chmod -R g=u /buildkit"``
