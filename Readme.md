# joplin-server

## About

This project offers prebuild Docker images from the Joplin server for amd64, armv7 and arm64 architectures,
as there are no official Docker images for the armv7 and arm64 architectures.

_Note: armv7 builds are currently failing (see https://github.com/infinityofspace/joplin-server/issues/1)_

## Usage

You can pull the image with:

```commandline
docker pull ghcr.io/infinityofspace/joplin-server:latest
```

The usage is identical to the official Docker image, which is described [here](https://hub.docker.com/r/joplin/server).

## Copyright Notices

Joplin is not affiliated with this project and Joplin® is a trademark of JOPLIN SAS.
The docker images are licensed with the original license of the server, we can be found [here](https://raw.githubusercontent.com/laurent22/joplin/dev/packages/server/LICENSE.md).
