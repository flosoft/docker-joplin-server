FROM node:16-bullseye

RUN apt-get update \
    && apt-get install -y \
    python \
    && rm -rf /var/lib/apt/lists/*

# Enables Yarn
RUN corepack enable

RUN echo "Node: $(node --version)"
RUN echo "Npm: $(npm --version)"
RUN echo "Yarn: $(yarn --version)"

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
COPY --chown=$user:$user .yarn ./.yarn
COPY --chown=$user:$user .yarnrc.yml .
COPY --chown=$user:$user yarn.lock .

RUN yarn install --inline-builds --mode=skip-build

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
COPY --chown=$user:$user packages/fork-uslug/package*.json ./packages/fork-uslug/
COPY --chown=$user:$user packages/htmlpack/package*.json ./packages/htmlpack/
COPY --chown=$user:$user packages/renderer/package*.json ./packages/renderer/
COPY --chown=$user:$user packages/tools/package*.json ./packages/tools/
COPY --chown=$user:$user packages/lib/package*.json ./packages/lib/
COPY --chown=$user:$user tsconfig.json .

# The following have postinstall scripts so we need to copy all the files.
# Since they should rarely change this is not an issue

COPY --chown=$user:$user packages/turndown ./packages/turndown
COPY --chown=$user:$user packages/turndown-plugin-gfm ./packages/turndown-plugin-gfm
COPY --chown=$user:$user packages/fork-htmlparser2 ./packages/fork-htmlparser2
COPY --chown=$user:$user packages/server/package*.json ./packages/server/

# Then bootstrap only, without compiling the TypeScript files

RUN yarn install --inline-builds --mode=skip-build

# Now copy the source files. Put lib and server last as they are more likely to change.

COPY --chown=$user:$user packages/fork-sax ./packages/fork-sax
COPY --chown=$user:$user packages/fork-uslug ./packages/fork-uslug
COPY --chown=$user:$user packages/htmlpack ./packages/htmlpack
COPY --chown=$user:$user packages/renderer ./packages/renderer
COPY --chown=$user:$user packages/tools ./packages/tools
COPY --chown=$user:$user packages/lib ./packages/lib
COPY --chown=$user:$user packages/server ./packages/server

# Finally build everything, in particular the TypeScript files. We can't just
# run `yarn run build` because that wouldn't run the postinstall scripts in
# dependencies (for example the sqlite3 native module would not be built). So
# instead we run `yarn install`, which is going to install again all the
# packages (but because it's already done it should be fast), and then run the
# postinstall scripts, as well as build scripts.

RUN yarn install

ENV RUNNING_IN_DOCKER=1
EXPOSE ${APP_PORT}

# Not clear what's the equivalent of "--prefix" in Yarn 3, so keep using npm for
# now.
CMD [ "npm", "--prefix", "packages/server", "start" ]

# Build-time metadata
# https://github.com/opencontainers/image-spec/blob/master/annotations.md
ARG BUILD_DATE
ARG REVISION
ARG VERSION
LABEL org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.title="Joplin Server" \
      org.opencontainers.image.description="Unofficial Docker image for Joplin Server" \
      org.opencontainers.image.url="https://github.com/flosoft/docker-joplin-server" \
      org.opencontainers.image.revision="$REVISION" \
      org.opencontainers.image.source="https://github.com/flosoft/docker-joplin-server.git" \
      org.opencontainers.image.version="${VERSION}"
