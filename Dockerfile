# Use Ubuntu 22.04 as base
FROM ubuntu:22.04

# Set environment variable to skip the tzdata configuration prompt
ENV DEBIAN_FRONTEND=noninteractive

# Install cURL, Python 3, sudo, unbuffer, and other required packages
RUN apt update && apt install -y     curl     python3     sudo     expect-dev     software-properties-common     squashfs-tools     squashfuse     git     python-setuptools     pkgconf     clang     binfmt-support     systemd     cmake     ninja-build     libncurses6     libncurses5     libtinfo5     libtinfo6     libncurses-dev     libsdl2-dev     libepoxy-dev     libssl-dev     llvm     lld     tzdata     qtbase5-dev     qtchooser     qt5-qmake     qtbase5-dev-tools     qml-module-qtquick2     qtdeclarative5-dev     libqt5qml5

# Add FEX repository
RUN add-apt-repository -y ppa:fex-emu/fex

# Clone the FEX repo
RUN git clone --recurse-submodules https://github.com/FEX-Emu/FEX.git

# Set working directory for FEX
WORKDIR FEX

# Modify CMakeLists.txt to use legacy binfmt_misc
RUN sed -i 's@USE_LEGACY_BINFMTMISC "Uses legacy method of setting up binfmt_misc" FALSE@USE_LEGACY_BINFMTMISC "Uses legacy method of setting up binfmt_misc" TRUE@' ./CMakeLists.txt

# Create Build directory and set it as the working directory
RUN mkdir Build
WORKDIR Build

# Compile FEX with Clang
RUN CC=clang CXX=clang++ cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DUSE_LINKER=lld -DENABLE_LTO=True -DBUILD_TESTS=False -DENABLE_ASSERTIONS=False -G Ninja ..
RUN ninja
RUN ninja install
RUN ninja binfmt_misc
RUN ninja binfmt_misc_64

# Create steam user
RUN useradd -m steam

# Install FEX root FS
RUN sudo -u steam bash -c "unbuffer FEXRootFSFetcher -y -x"

# Copy init-server.sh to the steam user's home directory and set correct permissions
COPY ./init-server.sh /home/steam/init-server.sh
RUN chown steam:steam /home/steam/init-server.sh && chmod +x /home/steam/init-server.sh

# Create the Steam directory and set ownership
RUN mkdir -p /home/steam/Steam && chown steam:steam /home/steam/Steam

# Set working directory to Steam
WORKDIR /home/steam/Steam

# Change user to steam
USER steam

# Debugging commands (optional)
RUN whoami && ls -alhtr /home/steam/init-server.sh

# Download and extract SteamCMD
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# Ensure init-server.sh is executable (redundant safety measure)
RUN chmod +x /home/steam/init-server.sh

# Run the init-server.sh script on container startup
ENTRYPOINT /home/steam/init-server.sh
