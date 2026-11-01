ARG BASE_IMAGE=ubuntu:24.04@sha256:fe81560990fae86dc4743202b2cb4d3df98d0bcf949173cecef15ce1127ef852
FROM ${BASE_IMAGE} AS build

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates clang cmake ninja-build pkg-config libgtk-3-dev \
    librsvg2-dev libgirepository1.0-dev libgdk-pixbuf-2.0-dev libgtk-3-bin \
    libgdk-pixbuf2.0-bin binutils patchelf curl jq \
    file desktop-file-utils xdg-user-dirs git rsync unzip xz-utils make g++ dpkg-dev \
    libssl-dev libunwind-dev libvulkan-dev libgl1-mesa-dev libglu1-mesa-dev \
    libasound2-dev libsecret-1-dev \
    && rm -rf /var/lib/apt/lists/*

COPY appimage-tools.json /opt/packaging/
RUN set -eu; curl --fail --location --retry 3 --connect-timeout 20 --max-time 600 \
    "$(jq -er .flutter.url /opt/packaging/appimage-tools.json)" --output /tmp/flutter.tar.xz \
    && printf '%s  /tmp/flutter.tar.xz\n' "$(jq -er .flutter.sha256 /opt/packaging/appimage-tools.json)" | sha256sum --check \
    && tar -xJf /tmp/flutter.tar.xz -C /opt && rm /tmp/flutter.tar.xz \
    && chmod -R a+rwX /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"

FROM ${BASE_IMAGE} AS runtime-test
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb xauth x11-utils x11-apps xdotool imagemagick dbus-x11 libgl1 libegl1 libgles2 \
  libgl1-mesa-dri fonts-dejavu-core \
  && rm -rf /var/lib/apt/lists/*