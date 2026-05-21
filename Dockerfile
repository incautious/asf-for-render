ARG ASF_VERSION=latest

FROM justarchi/archisteamfarm:${ASF_VERSION}

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  git bash netcat-openbsd rsync \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY ./plugins /app/plugins
COPY ./scripts /app/scripts

RUN chmod +x /app/scripts/*.sh

ENTRYPOINT ["/app/scripts/entrypoint.sh"]
