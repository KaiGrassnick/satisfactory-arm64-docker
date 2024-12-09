# Satisfactory Dedicated Server for ARM64 (Docker Container)

This Docker container provides a dedicated server for running Satisfactory on ARM64 architecture. It is based on [nitrog0d/palworld-arm64](https://github.com/nitrog0d/palworld-arm64).

NOTE: This Repository is an enhanced an updated fork of [RisedSky/satisfactory-arm64-docker](https://github.com/RisedSky/satisfactory-arm64-docker), which itself was a fork of [sa-shiro/Satisfactory-Dedicated-Server-ARM64-Docker](https://github.com/sa-shiro/Satisfactory-Dedicated-Server-ARM64-Docker)

---

## Reason for the fork
The original Project by sa-shiro looked like it was not maintained anymore.

The fork by RisedSky was a good start, but had some issues and was not updated for a while.

I wanted to use the container for my own server, so I decided to fork it and implement fixes to make the build run correctly.

During the progress, I encountered some issues and decided to improve the build process and the overall structure of the project.

## Changes
- Restructured the Dockerfile to decrease layer count and improve readability
- Remove the need for sudo in the Dockerfile
- Defined all the exposed ports in the Dockerfile
- Changed some paths to make the container more user-friendly
- Added the health check directly in the Dockerfile ( no need to use a separate script nor have jq installed on the host system )
- Added the possibility to switch between public and experimental branch
- Make use of named volumes instead of bind mounts
  - This change made it possible to remove the need for correct user / group ids
- Updated the init-server.sh script
  - to use paths defined in Dockerfile
  - link steam library only if it is not already linked
  - allow to change between public and experimental branch
- Remove build instruction from docker-compose.yml to make it more user-friendly and independent to use
- Add volume for steam files to speed up the start of the container

## Getting Started

1. **Download or Clone Repository**:
   Download or clone this repository to your desired folder, for example, `satisfactory-server`.
   ```sh
   git clone https://github.com/KaiGrassnick/satisfactory-arm64-docker.git
   cd satisfactory-arm64-docker
   ```

2. **Build the Docker Image**:
   Run the build script:

   ```sh
   sh build.sh
   ```

   If execution permission is denied, grant it:

   ```sh
   chmod u+x build.sh
   ```

3. **Run the Docker Image**:
   After the build process completes, start the Docker image either by running:

   ```sh
   sh run.sh
   ```

   Or via Docker Compose in detached mode:

   ```sh
   docker compose up -d
   ```

4. **Open Necessary Ports**:
   The following ports must be opened for the server to function properly:

   - TCP:
     - `7777`
   - UDP:
     - `7777`
     - `15000`
     - `15777`

   Ensure these ports are open using the Linux firewall of your choice and also within the Security List of the Oracle Cloud Infrastructure Network.

5. **Default Port**:
   The default port for the server is `7777`.

Now your Satisfactory Dedicated Server for ARM64 is ready!. Enjoy your gaming experience with friends.

## Accessing the Server files
In order to overcome any permission issues, the files are stored inside docker named volumes.

This is defined in the `docker-compose.yml` file:
```yml
    volumes:
      - 'server-files:/home/steam/sfserver'
      - 'config:/home/steam/.config/Epic'
```
In order to access the files, you can enter the container via:
```sh
docker compose exec satisfactory-server bash
```

or run:
```sh
sh interactive-shell.sh
```

Then you can access the files in `/home/steam/sfserver` and `/home/steam/.config/Epic`.

## Modifying Server Port Configuration

To alter the server port, you'll need to make adjustments in the `docker-compose.yml` file:

1. **docker-compose.yml**:
   Edit this file to expose the desired ports outside of the container and set the `$EXTRA_PARAMS` environment variable to configure additional parameters for the `FactoryServer.sh` script.

Ensure that these changes are made accurately to reflect your desired server port configuration.

### $EXTRA_PARAMS Options

| Option                     | Description                                                                                                                                                                                                                                           | Example                |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------- |
| -multihome=<ip address>    | Bind the server process to a specific IP address rather than all available interfaces                                                                                                                                                                 | -multihome=192.168.1.4 |
| -ServerQueryPort=<portnum> | Override the Query Port the server uses. This is the port specified in the Server Manager in the client UI to establish a server connection. This can be set freely. The default port is UDP/15777.                                                   | -ServerQueryPort=15000 |
| -BeaconPort=<portnum>      | Override the Beacon Port the server uses. As of Update 6, this port can be set freely. The default port is UDP/15000. If this port is already in use, the server will step up to the next port until an available one is found.                       | -BeaconPort=15001      |
| -Port=<portnum>            | Override the Game Port the server uses. This is the primary port used to communicate game telemetry with the client. The default port is UDP/7777. If it is already in use, the server will step up to the next port until an available one is found. | -Port=15002            |
| -DisablePacketRouting      | Startup argument for disabling the packet router (Automatically disabled with multihome)                                                                                                                                                              | -DisablePacketRouting  |

### Example usage:

```
EXTRA_PARAMS=-⁠ServerQueryPort=17531 -⁠BeaconPort=17532 -Port=17533
```

### Auto Update

If you want to check for game server updates, add the following to `docker-compose.yml`:
```
environment:
    - ALWAYS_UPDATE_ON_START=true
```

### Use Beta Branch

If you want to change from public to experimental, add the following to `docker-compose.yml`:
```
environment:
    - USE_EXPERIMENTAL=true
```