# https://versatile.nl/blog/deploying-lerna-web-apps-with-docker

FROM node:12

RUN apt-get update
RUN apt-get --yes install vim

ARG user=joplin
#ARG JOPLIN_VERSION=0.0


RUN useradd --create-home --shell /bin/bash $user
USER $user

ENV NODE_ENV development

WORKDIR /home/$user

RUN mkdir /home/$user/logs
RUN mkdir /home/$user/docker-src

#RUN wget -qO- https://github.com/laurent22/joplin/archive/${JOPLIN_VERSION}.tar.gz | tar xz --strip 1
RUN wget -qO- https://github.com/laurent22/joplin/archive/dev.tar.gz | tar xz --strip 1 -C /home/$user/docker-src

# To take advantage of the Docker cache, we first copy all the package.json
# and package-lock.json files, as they rarely change? and then bootstrap
# all the packages.
#
# Note that bootstrapping the packages will run all the postinstall
# scripts, which means that for packages that have such scripts, we need to
# copy all the files.
#
# We can't run boostrap with "--ignore-scripts" because that would
# prevent certain sub-packages, such as sqlite3, from being built

RUN cp /home/$user/docker-src/package*.json ./

# Install the root scripts but don't run postinstall (which would bootstrap
# and build TypeScript files, but we don't have the TypeScript files at
# this point)

RUN npm install --ignore-scripts

RUN mkdir -p ./packages/fork-sax/
RUN cp /home/$user/docker-src/packages/fork-sax/package*.json ./packages/fork-sax/
RUN mkdir -p ./packages/lib/
RUN cp /home/$user/docker-src/packages/lib/package*.json ./packages/lib/
RUN mkdir -p ./packages/renderer/
RUN cp /home/$user/docker-src/packages/renderer/package*.json ./packages/renderer/
RUN mkdir -p ./packages/tools/
RUN cp /home/$user/docker-src/packages/tools/package*.json ./packages/tools/
RUN mkdir -p ./packages/server/
RUN cp /home/$user/docker-src/packages/server/package*.json ./packages/server/
RUN cp /home/$user/docker-src/lerna.json .
RUN cp /home/$user/docker-src/tsconfig.json .

# The following have postinstall scripts so we need to copy all the files.
# Since they should rarely change this is not an issue

RUN cp -r /home/$user/docker-src/packages/turndown ./packages/turndown
RUN cp -r /home/$user/docker-src/packages/turndown-plugin-gfm ./packages/turndown-plugin-gfm
RUN cp -r /home/$user/docker-src/packages/fork-htmlparser2 ./packages/fork-htmlparser2

RUN ls -la /home/$user

# Then bootstrap only, without compiling the TypeScript files

RUN npm run bootstrap

RUN cp -r /home/$user/docker-src/packages/fork-sax ./packages/
RUN cp -r /home/$user/docker-src/packages/lib ./packages/
RUN cp -r /home/$user/docker-src/packages/renderer ./packages/
RUN cp -r /home/$user/docker-src/packages/tools ./packages/
RUN cp -r /home/$user/docker-src/packages/server ./packages/

RUN cp /home/$user/docker-src/tsconfig.json ./
RUN rm -rf /home/$user/docker-src/

# Finally build everything, in particular the TypeScript files.

RUN npm run build


EXPOSE 22300

CMD [ "npm", "--prefix", "packages/server", "start" ]
