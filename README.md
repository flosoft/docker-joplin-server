# docker-joplin-server

[![Docker Build Status](https://img.shields.io/github/workflow/status/flosoft/docker-joplin-server/ci?label=docker%20build&style=for-the-badge)](https://hub.docker.com/r/florider89/joplin-server/) [![Docker Pulls](https://img.shields.io/docker/pulls/florider89/joplin-server.svg?style=for-the-badge)](https://hub.docker.com/r/florider89/joplin-server/)

A Docker Image to run [Joplin Server](https://github.com/laurent22/joplin/tree/dev/packages/server).

## IMPORTANT - v1 to v2 breaking change!
With Joplin Server v2 coming soon, please be sure to read the post on the [Joplin forum](https://discourse.joplinapp.org/t/major-breaking-change-in-coming-joplin-server-2-0/17254?u=florider).
Note that data will not be migrated - and you need to start fresh again as explained in the forum post.
You'll be able to continue to use the following tag for v1: `docker pull florider89/joplin-server:1.7.2`

Current V2 tags: `master`.

![Joplin Server](https://p195.p4.n0.cdn.getcloudapp.com/items/L1uO8yx1/dc01a283-f2fc-453b-a504-61857ca9c663.png?v=82a88bf8a1e9119f9fa2a511ffe3c55a)

You can find more information about Joplin on their [website](https://joplinapp.org/) or [Github](https://github.com/laurent22/joplin/).

## Environment Variables

*Please note the change of `JOPLIN_BASE_URL` and `JOPLIN_PORT` to the new `APP_` environment variables from version 1.6.4 to 1.7!*

| Environment Variable | Required | Example Value              | Description                                            |
| -------------------- | -------- | -------------------------- | ------------------------------------------------------ |
| `APP_BASE_URL`       | Yes      | https://joplin.your.domain | The URL where your Joplin Instance will be served from |
| `APP_PORT`           | Yes      | 22300                      | The port on which your Joplin instance will be running |
| `DB_CLIENT`          | No       | pg                         | Use `pg` for postgres.                                 |
| `POSTGRES_PASSWORD`  | No       | joplin                     | Postgres DB password                                   |
| `POSTGRES_DATABASE`  | No       | joplin                     | Postgres DB name                                       |
| `POSTGRES_USER`      | No       | joplin                     | Postgres Username                                      |
| `POSTGRES_PORT`      | No       | 5432                       | Postgres DB port                                       |
| `POSTGRES_HOST`      | No       | db                         | Postgres DB Host                                       |

## Usage

I would recommend using a frontend webserver to run Joplin over HTTPS.

### Generic docker-compose.yml

This is a barebones docker-compose example. It is recommended to use a webserver in front of the instance to run it over HTTPS. See the example below using Traefik.

```yaml
version: '3'
services:
    app:
        environment:
            - APP_BASE_URL=http://joplin.yourdomain.tld:22300
            - APP_PORT=22300
            - POSTGRES_PASSWORD=joplin
            - POSTGRES_DATABASE=joplin
            - POSTGRES_USER=joplin 
            - POSTGRES_PORT=5432 
            - POSTGRES_HOST=db
            - DB_CLIENT=pg
        restart: unless-stopped
        image: florider89/joplin-server:latest
        ports:
            - "22300:22300"
    db:
        restart: unless-stopped
        image: postgres:13.1
        ports:
            - "5432:5432"
        volumes:
            - /foo/bar/joplin-data:/var/lib/postgresql/data
        environment:
            - POSTGRES_PASSWORD=joplin
            - POSTGRES_USER=joplin
            - POSTGRES_DB=joplin
```





### Traefik docker-compose.yml

The following `docker-compose.yml` will make Joplin Server run and apply the labels to expose itself to Traefik.

Note that there are 2 networks in the example below, one to talk to traefik (`traefik_default`) and one between the Joplin Server and the Database, ensuring that these hosts are not exposed.

You may need to double check the entrypoint name (`websecure`) and certresolver (`lewildcardresolver`) to match your Traefik configuration

```yaml
version: '3'

services:
    app:
        environment:
            - APP_BASE_URL=https://joplin.yourdomain.tld
            - APP_PORT=22300
            - POSTGRES_PASSWORD=joplin
            - POSTGRES_DATABASE=joplin
            - POSTGRES_USER=joplin
            - POSTGRES_PORT=5432
            - POSTGRES_HOST=db
            - DB_CLIENT=pg
        restart: unless-stopped
        image: florider89/joplin-server:latest
        networks:
            - internal
            - traefik_default
        labels:
            - "traefik.enable=true"
            - "traefik.http.routers.joplin.rule=Host(`joplin.yourdomain.tld`)"
            - "traefik.http.routers.joplin.entrypoints=websecure"
            - "traefik.http.routers.joplin.tls=true"
            - "traefik.http.routers.joplin.tls.certresolver=lewildcardresolver"
            - "traefik.http.middlewares.sslheader.headers.customrequestheaders.X-Forwarded-Proto = http"
            - "traefik.http.routers.joplin.service=joplin-server"
            - "traefik.http.services.joplin-server.loadbalancer.passhostheader=true"
            - "traefik.http.services.joplin-server.loadbalancer.server.port=22300"
            - "traefik.docker.network=traefik_default"
    db:
        restart: unless-stopped
        image: postgres:13.1
        networks:
            - internal
        volumes:
            - /foo/bar/joplin-data:/var/lib/postgresql/data
        environment:
            - POSTGRES_PASSWORD=joplin
            - POSTGRES_USER=joplin
            - POSTGRES_DB=joplin
networks:
  internal:
    internal: true
  traefik_default:
    external: true
```

## Tags

Currently there is only one version as there is no release yet for the server.

`latest`: Latest server release as per recommended Dockerfile.

`latest-alpine`: EXPERIMENTAL builds using Alpine of latest release.

`master[-alpine]`: Images built testing CI / Image changes. Should not be used on systems you want to have a working instance of Joplin Server on. Currently V2 Beta - see notice at the top!

## Contribute

Feel free to contribute to this Docker image on [Github](https://github.com/flosoft/docker-joplin-server).
