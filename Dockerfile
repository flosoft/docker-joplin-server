FROM node:15-alpine

ARG user=joplin
#ARG JOPLIN_VERSION=0.0


#RUN useradd --create-home --shell /bin/bash $user
RUN adduser --home /home/$user --disabled-password $user
USER $user

ENV NODE_ENV development

WORKDIR /home/$user

#RUN wget -qO- https://github.com/laurent22/joplin/archive/${JOPLIN_VERSION}.tar.gz | tar xz --strip 1
RUN mkdir /home/$user/logs \
  && mkdir /home/$user/docker-src \
  && wget -qO- https://github.com/laurent22/joplin/archive/dev.tar.gz | tar xz --strip 1 -C /home/$user/docker-src \
  && cp /home/$user/docker-src/package*.json ./ \
  && cp -r /home/$user/docker-src/packages/fork-sax ./packages/ \
  && cp -r /home/$user/docker-src/packages/lib ./packages/ \
  && cp -r /home/$user/docker-src/packages/renderer ./packages/ \
  && cp -r /home/$user/docker-src/packages/tools ./packages/ \
  && cp -r /home/$user/docker-src/packages/server ./packages/ \
  && cp /home/$user/docker-src/lerna.json . \
  && cp /home/$user/docker-src/tsconfig.json . \
  && cp -r /home/$user/docker-src/packages/turndown ./packages/turndown \
  && cp -r /home/$user/docker-src/packages/turndown-plugin-gfm ./packages/turndown-plugin-gfm \
  && cp -r /home/$user/docker-src/packages/fork-htmlparser2 ./packages/fork-htmlparser2 \
  && cp /home/$user/docker-src/tsconfig.json ./ \
  && rm -rf /home/$user/docker-src/

RUN ls -l
#RUN npm install --ignore-scripts
RUN npm ci --ignore-scripts

RUN ls -l
RUN npm run bootstrap
RUN ls -l
RUN npm run build


EXPOSE 22300

CMD [ "npm", "--prefix", "packages/server", "start" ]
