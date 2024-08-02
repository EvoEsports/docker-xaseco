<p align="center">
  <img src="https://github.com/user-attachments/assets/b903eb8c-f1ea-45f7-ae22-313498c1939c" alt="Trackmania image" height="100"/>
<p align="center">
    <a href="https://hub.docker.com/r/evoesports/xaseco">
        <img src="https://img.shields.io/docker/stars/evoesports/xaseco?&style=flat-square"
            alt="docker stars"></a>
    <a href="https://hub.docker.com/r/evoesports/xaseco">
        <img src="https://img.shields.io/docker/pulls/evoesports/xaseco?style=flat-square"
            alt="docker pulls"></a>
    <a href="https://hub.docker.com/r/evoesports/xaseco">
        <img src="https://img.shields.io/docker/v/evoesports/xaseco?style=flat-square"
            alt="docker image version"></a>
    <a href="https://hub.docker.com/r/evoesports/xaseco">
        <img src="https://img.shields.io/docker/image-size/evoesports/xaseco?style=flat-square"
            alt="docker image size"></a>
    <a href="https://discord.gg/evoesports">
        <img src="https://img.shields.io/discord/384138149686935562?color=%235865F2&label=discord&logo=discord&logoColor=%23ffffff&style=flat-square"
            alt="chat on Discord"></a>
</p>

## Table of Contents
- [Table of Contents](#table-of-contents)
- [Description](#description)
- [How to use this image](#how-to-use-this-image)
  - [... with 'docker compose'](#-with-docker-compose)
- [Environment Variables](#environment-variables)
- [Contributing](#contributing)

## Description
This docker image of XASECO is using [Remi Collet's PHP 5.6.40 source](https://github.com/remicollet/php-src-security/tree/PHP-5.6-security-backports-openssl11) with security backports from newer PHP versions.
Additionally it contains several PHP [patches](https://github.com/shivammathur/php-src-backports/tree/main/patches) that, among some other small fixes and adjustments, also allows the compilation with OpenSSL 3.0 and above.
Of course, the whole image is also based on the [Alpine](https://hub.docker.com/_/alpine) docker base image to reduce the attack surface and container size.

## How to use this image
### ... with 'docker compose'
To do the same with `docker compose`:
```yaml
services:
  trackmania:
    image: evoesports/trackmaniaforever:latest
    restart: unless-stopped
    ports:
      - 2350:2350/udp
      - 2350:2350/tcp
      - 3450:3450/udp
      - 3450:3450/tcp
    environment:
      TMF_SERVER_NAME: "Yet another server"
      TMF_MASTERSERVER_LOGIN: "YOUR_MASTERSERVER_LOGIN"
      TMF_MASTERSERVER_PASSWORD: "YOUR_MASTERSERVER_PASSWORD"
      TMF_SYSTEM_XMLRPC_ALLOWREMOTE: "True"
      TMF_SYSTEM_PACKMASK: "united"
      TMF_SYSTEM_FORCE_IP_ADDRESS: "YOUR_EXTERNAL_IPV4:PORT"
    volumes:
      - "trackmania:/server/GameData"
  xaseco:
    image: evoesports/xaseco:latest
    restart: unless-stopped
    depends_on:
      trackmania:
        condition: service_healthy
        restart: true
    environment:
      XASECO_TMSERVER_LOGIN: "SuperAdmin"
      XASECO_TMSERVER_PASSWORD: "SuperAdmin"
      XASECO_TMSERVER_IP: "trackmania"
      XASECO_TMSERVER_PORT: "5000"
      XASECO_MYSQL_SERVER: "YOUR_MYSQL_ADDRESS"
      XASECO_MYSQL_LOGIN: "xaseco"
      XASECO_MYSQL_PASSWORD: "YOUR_MYSQL_PASSWORD"
      XASECO_MYSQL_DATABASE: "xaseco"
      XASECO_DEDIMANIA_LOGIN: "YOUR_MASTERSERVER_LOGIN"
      XASECO_DEDIMANIA_PASSWORD: "YOUR_MASTERSERVER_PASSWORD"
      XASECO_DEDIMANIA_NATION: "OTH" # remember to set this to the actual country
      XASECO_MASTERADMINS: "login1,login2,login3"
    volumes:
      - "xaseco:/xaseco"
      - "trackmania:/server/GameData"
volumes:
  xaseco: null
  trackmania: null
```
Since XASECO is saving it's config files in the root directory, the whole XASECO directory needs to be exposed as volume, which means the whole installation of XASECO is stored in the volume, not just the config files. Every time the container gets restarted, the entrypoint extracts XASECO fresh into the volume, but leaves config files and plugins untouched. That also means that all files that are not plugins or config files get overwritten on every container restart, which also means that deleting and/or modifying crucial XASECO files have no effect.

## Environment Variables
| **Environment Variable**                  | **Description**                                                                                                                       | **Default Value**                 | **Required** |
|-------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------|:------------:|
| `XASECO_MODE`                             | The game version the server is running. Can be TMF or TMN.                                                                            | TMF                               |       ✔      |
| `XASECO_TMSERVER_LOGIN`                   | The SuperAdmin user configured in the TM server.                                                                                      | SuperAdmin                        |       ✔      |
| `XASECO_TMSERVER_PASSWORD`                | The SuperAdmin password configured in the TM server.                                                                                  | SuperAdmin                        |       ✔      |
| `XASECO_TMSERVER_IP`                      | The IP address of the TM server.                                                                                                      |                                   |       ✔      |
| `XASECO_TMSERVER_PORT`                    | The port of the TM server XMLRPC.                                                                                                     |                                   |       ✔      |
| `XASECO_MYSQL_SERVER`                     | The mysql server IP address.                                                                                                          |                                   |       ✔      |
| `XASECO_MYSQL_PASSWORD`                   | The mysql server password.                                                                                                            |                                   |       ✔      |
| `XASECO_MYSQL_DATABASE`                   | The mysql database name.                                                                                                              |                                   |       ✔      |
| `XASECO_DEDIMANIA_LOGIN`                  | The Nadeo masterserver login also used on the server.                                                                                 |                                   |       ✔      |
| `XASECO_DEDIMANIA_PASSWORD`               | The Nadeo masterserver password also used on the server. Communitycode is not working anymore.                                        |                                   |       ✔      |
| `XASECO_DEDIMANIA_NATION`                 | The [ISO 3166-1 alpha-3 code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3) of the country the server is listed under. (e.g. DEU) The default value stands for "Other countries". | OTH                               |       ✔      |
| `XASECO_MASTERADMINS`                     | Comma seperated list of masteradmins. (e.g. login1,login2,login3)                                                                     |                                   |       ✔      |

[^1]: Default value of this docker image. Does not represent the defaults by the TrackMania server provided by Ubisoft Nadeo.

## Contributing
If you have any questions, issues, bugs or suggestions, don't hesitate and open an [Issue](https://github.com/evoesports/docker-trackmaniaforever/issues/new)! You can also join our [Discord](https://discord.gg/evoesports) for questions.

You may also help with development by creating a pull request.
