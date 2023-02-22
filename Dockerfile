FROM elixir:1.14-otp-25-alpine as builder

ARG PLEROMA_VERSION=stable
ARG PLEROMA_REPO=https://git.pleroma.social/pleroma/pleroma.git
ENV MIX_ENV=prod

# Install build dependencies
RUN apk add --no-cache git gcc g++ musl-dev make cmake file-dev ncurses postgresql-client imagemagick libmagic ffmpeg exiftool

WORKDIR /app
RUN git clone --filter=blob:none --no-checkout ${PLEROMA_REPO} . \
  && git checkout ${PLEROMA_VERSION}


RUN echo "import Mix.Config" > config/prod.secret.exs \
  && mix local.hex --force \
  && mix local.rebar --force \
  && mix deps.get --only prod \
  && mix deps.compile

FROM elixir:1.14-otp-25-alpine as runner
ENV MIX_ENV=prod
ARG EXTRA_PKGS="imagemagick libmagic ffmpeg"

# Install runtime dependencies
RUN apk add --no-cache shadow su-exec git postgresql-client exiftool ${EXTRA_PKGS}
WORKDIR /app

ARG PUID=1000
ARG PGID=1000

ADD start.sh /app/start.sh
ADD cli.sh /app/cli.sh
RUN groupmod -g $PGID users \
  && useradd -u $PUID -U -d /home/pleroma -s /bin/false pleroma \
  && usermod -G users pleroma \
  && chmod +x /app/start.sh \
  && chmod +x /app/cli.sh \
  && mkdir -p \ /data/uploads /data/static \
  && chown -R pleroma:users /data /app

COPY --from=builder --chown=pleroma /root/.mix /home/pleroma/.mix
COPY --from=builder --chown=pleroma /app .

ADD base-config.exs /app/config/prod.secret.exs

EXPOSE 4000
ENTRYPOINT ["/app/start.sh"]
