# docker-joplin-server

[![Docker Build Status](https://img.shields.io/github/workflow/status/flosoft/docker-joplin-server/ci?label=docker%20build&style=for-the-badge)](https://hub.docker.com/r/florider89/joplin-server/) [![Docker Pulls](https://img.shields.io/docker/pulls/florider89/joplin-server.svg?style=for-the-badge)](https://hub.docker.com/r/florider89/joplin-server/)

A Docker Image to run [Joplin Server](https://github.com/laurent22/joplin/tree/dev/packages/server).

![Joplin Server](https://p195.p4.n0.cdn.getcloudapp.com/items/L1uO8yx1/dc01a283-f2fc-453b-a504-61857ca9c663.png?v=82a88bf8a1e9119f9fa2a511ffe3c55a)

You can find more information about Joplin on their [website](https://joplinapp.org/) or [Github](https://github.com/laurent22/joplin/).

## Usage

The following `docker-compose.yml` will make Joplin Server available on 22300. There are 2 networks in the example below, one to talk to traefik and one between the Joplin Server and the Database.

```yaml
version: '3'

services:
    app:
        environment:
            - JOPLIN_BASE_URL=https://joplin.your-domain.tld
            - JOPLIN_PORT=22300
        restart: unless-stopped
        image: florider89/joplin-server:latest
        #build:
        #    context: .
        #    dockerfile: Dockerfile.server
        #ports:
        #    - "${JOPLIN_PORT}:${JOPLIN_PORT}"
        # volumes:
        #     # Mount the server directory so that it's possible to edit file
        #     # while the container is running. However don't mount the
        #     # node_modules directory which will be specific to the Docker
        #     # image (eg native modules will be built for Ubuntu, while the
        #     # container might be running in Windows)
        #     # https://stackoverflow.com/a/37898591/561309
        #     - ./packages/server:/home/joplin/packages/server
        #     - /home/joplin/packages/server/node_modules/
        networks:
            - internal
            - traefik_default
    db:
        restart: unless-stopped
        # By default, the Postgres image saves the data to a Docker volume,
        # so it persists whenever the server is restarted using
        # `docker-compose up`. Note that it would however be deleted when
        # running `docker-compose down`.
        #build:
        #    context: .
        #    dockerfile: Dockerfile.db
        image: postgres:13.1
        #ports:
        #    - "5432:5432"
        networks:
            - internal
        volumes:
            - /your/host/directory:/var/lib/postgresql/data
        environment:
            # TODO: Considering the database is only exposed to the
            # application, and not to the outside world, is there a need to
            # pick a secure password?
            - POSTGRES_PASSWORD=joplin
            - POSTGRES_USER=joplin
            - POSTGRES_DB=joplin
networks:
  internal:
    internal: true
  traefik_default:
    external: true
```

You will need to put a front-end server to serve the content. I'd recommend traefik.

## Tags

Currently there is only one version as there is no release yet for the server.

`latest`: Latest server release as per recommended Dockerfile.

`latest-alpine`: EXPERIMENTAL builds using Alpine of latest release.

`master[-alpine]`: Images built testing CI / Image changes. Should not be used on systems you want to have a working instance of Joplin Server on.

## Contribute

Feel free to contribute to this Docker image on [Github](https://github.com/flosoft/docker-joplin-server).
