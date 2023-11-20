# =============================================================================
# Build stage
# =============================================================================

FROM node:18-bullseye AS builder

ARG VERSION=dev

RUN apt-get update \
    && apt-get install -y \
    python tini rsync \
    && rm -rf /var/lib/apt/lists/*

# Enables Yarn
RUN corepack enable

WORKDIR /code

RUN git clone --depth 1 -b ${VERSION} https://github.com/laurent22/joplin.git .

WORKDIR /build

RUN mkdir -p ./.yarn && cp -r /code/.yarn/plugins ./.yarn/plugins \
    && cp -r /code/.yarn/releases ./.yarn \
    && cp -r /code/.yarn/patches ./.yarn \
    && cp /code/package.json . \
    && cp /code/.yarnrc.yml . \
    && cp /code/yarn.lock . \
    && cp /code/gulpfile.js . \
    && cp /code/tsconfig.json . \
    && mkdir -p ./packages && cp -r /code/packages/turndown ./packages \
    && cp -r /code/packages/turndown-plugin-gfm ./packages \
    && cp -r /code/packages/fork-htmlparser2 ./packages \
    && cp -r /code/packages/fork-sax ./packages \
    && cp -r /code/packages/fork-uslug ./packages \
    && cp -r /code/packages/htmlpack ./packages \
    && cp -r /code/packages/renderer ./packages \
    && cp -r /code/packages/tools ./packages \
    && cp -r /code/packages/utils ./packages \
    && cp -r /code/packages/lib ./packages \
    && cp -r /code/packages/server ./packages

# For some reason there's both a .yarn/cache and .yarn/berry/cache that are
# being generated, and both have the same content. Not clear why it does this
# but we can delete it anyway. We can delete the cache because we use
# `nodeLinker: node-modules`. If we ever implement Zero Install, we'll need to
# keep the cache.
#
# Note that `yarn install` ignores `NODE_ENV=production` and will install dev
# dependencies too, but this is fine because we need them to build the app.

RUN BUILD_SEQUENCIAL=1 yarn install --inline-builds \
    && yarn cache clean \
    && rm -rf .yarn/berry

# =============================================================================
# Final stage - we copy only the relevant files from the build stage and start
# from a smaller base image.
# =============================================================================

FROM node:18-bullseye-slim

ARG user=joplin
RUN useradd --create-home --shell /bin/bash $user

USER $user

COPY --chown=$user:$user --from=builder /build/packages /home/$user/packages
COPY --chown=$user:$user --from=builder /usr/bin/tini /usr/local/bin/tini

ENV NODE_ENV=production
ENV RUNNING_IN_DOCKER=1
EXPOSE ${APP_PORT}

# Use Tini to start Joplin Server:
# https://github.com/nodejs/docker-node/blob/main/docs/BestPractices.md#handling-kernel-signals
WORKDIR /home/$user/packages/server
ENTRYPOINT ["tini", "--"]
CMD ["yarn", "start-prod"]

# Build-time metadata
# https://github.com/opencontainers/image-spec/blob/master/annotations.md
ARG BUILD_DATE
ARG REVISION
ARG VERSION
LABEL org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.title="Joplin Server" \
      org.opencontainers.image.description="Docker image for Joplin Server" \
      org.opencontainers.image.url="https://joplinapp.org/" \
      org.opencontainers.image.revision="$REVISION" \
      org.opencontainers.image.source="https://github.com/infinityofspace/joplin-server.git" \
      org.opencontainers.image.version="${VERSION}"