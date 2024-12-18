# Stage 1: Build stage (base image with all build dependencies)
FROM ubuntu:22.04 AS build

ENV DEBIAN_FRONTEND=noninteractive

# Install necessary build dependencies
RUN apt-get update \
    && apt-get install -y \
    curl \
    python3 \
    sudo \
    telnet \
    expect-dev \
    software-properties-common \
    squashfs-tools \
    squashfuse \
    git \
    python-setuptools \
    pkgconf \
    clang \
    binfmt-support \
    systemd \
    cmake \
    ninja-build \
    libncurses6 \
    libncurses5 \
    libtinfo5 \
    libtinfo6 \
    libncurses-dev \
    libsdl2-dev \
    libepoxy-dev \
    libssl-dev \
    llvm \
    lld \
    tzdata \
    qtbase5-dev \
    qtchooser \
    qt5-qmake \
    qtbase5-dev-tools \
    qml-module-qtquick2 \
    qtdeclarative5-dev \
    libqt5qml5

# Add FEX repository and clone the FEX repo
RUN add-apt-repository -y ppa:fex-emu/fex \
    && git clone --recurse-submodules https://github.com/FEX-Emu/FEX.git

WORKDIR /FEX

# Modify CMakeLists.txt to use legacy binfmt_misc
RUN sed -i 's@USE_LEGACY_BINFMTMISC "Uses legacy method of setting up binfmt_misc" FALSE@USE_LEGACY_BINFMTMISC "Uses legacy method of setting up binfmt_misc" TRUE@' ./CMakeLists.txt

# Create Build directory and set it as the working directory
RUN mkdir /FEX/build
WORKDIR /FEX/build

# Compile FEX with Clang
RUN CC=clang CXX=clang++ cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DUSE_LINKER=lld -DENABLE_LTO=True -DBUILD_TESTS=False -DENABLE_ASSERTIONS=False -G Ninja ..
RUN ninja
RUN ninja install
RUN ninja binfmt_misc
RUN ninja binfmt_misc_64

# Stage 2: Runtime stage (slimmer image for final runtime)
FROM ubuntu:22.04 AS runtime

ARG DOCKER_USER=1000
ARG DOCKER_GROUP=1000

ENV DOCKER_USER=${DOCKER_USER}
ENV DOCKER_GROUP=${DOCKER_GROUP}
ENV DEBIAN_FRONTEND=noninteractive

# Install only the necessary runtime dependencies
RUN apt-get update \
    && apt-get install -y curl expect-dev binfmt-support systemd jq

# Create steam group and user
RUN groupadd -g ${DOCKER_GROUP} steam \
    && useradd -m -u ${DOCKER_USER} -g ${DOCKER_GROUP} steam

# Copy the compiled FEX from the build stage to the runtime stage
COPY --from=build /usr /usr

# Switch to the steam user
USER steam

# Install FEX root FS
RUN unbuffer FEXRootFSFetcher -y -x

# Switch to the root user
USER root

ENV STEAM_PATH=/home/steam/Steam

# Create the Steam directory and set ownership
RUN mkdir -p "${STEAM_PATH}" \
    && chown -R steam:steam "${STEAM_PATH}"

ENV STEAM_CONFIG_PATH=/home/steam/.config

# Create the Steam config directory and set ownership
RUN mkdir -p "${STEAM_CONFIG_PATH}" \
    && chown -R steam:steam "${STEAM_CONFIG_PATH}"

# Copy init-server.sh to the steam user's home directory
COPY ./init-server.sh /home/steam/init-server.sh

# Ensure proper ownership and set the script as executable
RUN chown steam:steam /home/steam/init-server.sh \
    && chmod 755 /home/steam/init-server.sh \
    && chmod +x /home/steam/init-server.sh

# Create the sfserver directory and set ownership
RUN mkdir -p /home/steam/sfserver \
    && chown -R steam:steam /home/steam/sfserver

# Switch to the steam user
USER steam

# Set the working directory to the Steam directory
WORKDIR "${STEAM_PATH}"

# Download and extract SteamCMD
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar xvfz -

# Set the working directory to the sfserver directory
ENV SF_SERVER_PATH=/home/steam/sfserver
WORKDIR ${SF_SERVER_PATH}

# Add Container Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=120s \
  CMD curl -k -f -s -S -X POST "https://127.0.0.1:7777/api/v1" \
      -H "Content-Type: application/json" \
      -d '{"function":"HealthCheck","data":{"clientCustomData":""}}' \
      | jq -e '.data.health == "healthy"' || exit 1

# Define Exposed Ports
EXPOSE 15777/udp 15000/udp 7777/udp 7777/tcp

# Execute init-server.sh on container startup using JSON format for ENTRYPOINT
ENTRYPOINT ["/home/steam/init-server.sh"]
