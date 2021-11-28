# https://versatile.nl/blog/deploying-lerna-web-apps-with-docker

FROM node:16-bullseye
#FROM ubuntu:20.10

#RUN apt-get update
#python3 as sqlite3 is failing to build
# https://github.com/mapbox/node-sqlite3/issues/1413
#RUN apt-get --yes install nodejs npm git python3
#RUN apt-get --yes install git python3
RUN apt-get update \
    && apt-get install -y \
    python \
    cmake \
    && rm -rf /var/lib/apt/lists/*

#RUN ln -sf python3 /usr/bin/python
#RUN npm config set python "$(which python3)"

ARG user=joplin

RUN useradd --create-home --shell /bin/bash $user
USER $user

ENV NODE_ENV development

WORKDIR /home/$user

RUN mkdir /home/$user/logs

# Install the root scripts but don't run postinstall (which would bootstrap
# and build TypeScript files, but we don't have the TypeScript files at
# this point)

COPY --chown=$user:$user package*.json ./
# If we're getting certificate errors, this is the fix.
#RUN npm config set registry http://registry.npmjs.org/
RUN npm install --ignore-scripts

# To take advantage of the Docker cache, we first copy all the package.json
# and package-lock.json files, as they rarely change, and then bootstrap
# all the packages.
#
# Note that bootstrapping the packages will run all the postinstall
# scripts, which means that for packages that have such scripts, we need to
# copy all the files.
#
# We can't run boostrap with "--ignore-scripts" because that would
# prevent certain sub-packages, such as sqlite3, from being built

COPY --chown=$user:$user packages/fork-sax/package*.json ./packages/fork-sax/
COPY --chown=$user:$user packages/htmlpack/package*.json ./packages/htmlpack/
COPY --chown=$user:$user packages/renderer/package*.json ./packages/renderer/
COPY --chown=$user:$user packages/tools/package*.json ./packages/tools/
COPY --chown=$user:$user packages/lib/package*.json ./packages/lib/
COPY --chown=$user:$user lerna.json .
COPY --chown=$user:$user tsconfig.json .

# The following have postinstall scripts so we need to copy all the files.
# Since they should rarely change this is not an issue

COPY --chown=$user:$user packages/turndown ./packages/turndown
COPY --chown=$user:$user packages/turndown-plugin-gfm ./packages/turndown-plugin-gfm
COPY --chown=$user:$user packages/fork-htmlparser2 ./packages/fork-htmlparser2

# Then bootstrap only, without compiling the TypeScript files
RUN npm run bootstrap

# We have a separate step for the server files because they are more likely to
# change.

COPY --chown=$user:$user packages/server/package*.json ./packages/server/
RUN npm run bootstrapServerOnly

# Now copy the source files. Put lib and server last as they are more likely to change.

COPY --chown=$user:$user packages/fork-sax ./packages/fork-sax
COPY --chown=$user:$user packages/htmlpack ./packages/htmlpack
COPY --chown=$user:$user packages/renderer ./packages/renderer
COPY --chown=$user:$user packages/tools ./packages/tools
COPY --chown=$user:$user packages/lib ./packages/lib
COPY --chown=$user:$user packages/server ./packages/server

# Finally build everything, in particular the TypeScript files.

RUN npm run build

EXPOSE ${APP_PORT}

CMD [ "npm", "--prefix", "packages/server", "start" ]
