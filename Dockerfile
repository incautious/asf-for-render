ARG ASF_VERSION

FROM justarchi/archisteamfarm:${ASF_VERSION}

RUN apt-get update \
  && apt-get install -y git bash netcat-openbsd rsync \
  && apt-get clean

WORKDIR /app

COPY ./plugins /app/plugins
COPY ./scripts /app/scripts

RUN chmod -R +x /app/scripts/*.sh

ENTRYPOINT ["/app/scripts/entrypoint.sh"]
