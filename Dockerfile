
# Stage 1: Build stage (base image with all build dependencies)
FROM ubuntu:22.04 AS build

ENV DEBIAN_FRONTEND=noninteractive

# Install necessary build dependencies
RUN apt update && apt install -y \
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
RUN add-apt-repository -y ppa:fex-emu/fex && \
    git clone --recurse-submodules https://github.com/FEX-Emu/FEX.git

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
FROM ubuntu:22.04

ARG DOCKER_USER
ARG DOCKER_GROUP

ENV USER_ID=${USER_ID}
ENV GROUP_ID=${GROUP_ID}
ENV DEBIAN_FRONTEND=noninteractive

# Install only the necessary runtime dependencies
RUN apt update && apt install -y curl sudo expect-dev binfmt-support systemd

# Create steam user
RUN useradd -m -u ${USER_ID} -g ${GROUP_ID} steam

# Copy the compiled FEX from the build stage to the runtime stage
COPY --from=build /usr /usr

# Install FEX root FS
RUN sudo -u steam bash -c "unbuffer FEXRootFSFetcher -y -x"

# Copy init-server.sh to the steam user's home directory
COPY ./init-server.sh /home/steam/init-server.sh

# Ensure proper ownership and set the script as executable
RUN chown steam:steam /home/steam/init-server.sh && chmod 755 /home/steam/init-server.sh
RUN chmod +x /home/steam/init-server.sh
# Create the Steam directory and set ownership
RUN mkdir -p /home/steam/Steam && chown -R steam:steam /home/steam/Steam

WORKDIR /home/steam/Steam

# Change to the steam user
USER steam

# Download and extract SteamCMD
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# Double-check permissions of init-server.sh
RUN ls -alh /home/steam/init-server.sh

# Execute init-server.sh on container startup using JSON format for ENTRYPOINT
ENTRYPOINT ["/home/steam/init-server.sh"]
