GnuTLS for Windows (MSVC)
=========================
[![CI](https://github.com/savoirfairelinux/gnutls/actions/workflows/ci.yml/badge.svg)](https://github.com/savoirfairelinux/gnutls/actions/workflows/ci.yml)
[![GitHub release](https://img.shields.io/github/release/savoirfairelinux/gnutls.svg)](https://github.com/savoirfairelinux/gnutls/releases/latest)
[![GitHub issues](https://img.shields.io/github/issues/savoirfairelinux/gnutls.svg)](https://github.com/savoirfairelinux/gnutls/issues)
[![license](https://img.shields.io/github/license/savoirfairelinux/gnutls.svg)](https://github.com/savoirfairelinux/gnutls)

> **Note**: This project is maintained by [Savoir-faire Linux](https://www.savoirfairelinux.com/), taking over maintenance from ShiftMediaProject. It provides native Windows MSVC build support and serves as the source repository for the `gnutls` port for Windows (x64 and x86) in vcpkg.

## Overview

This project provides native Microsoft Visual Studio (MSVC) build projects and fixes for **GnuTLS** and its dependencies on Windows.

## GnuTLS

GnuTLS is a secure communications library implementing the SSL, TLS and DTLS protocols and technologies around them. [https://www.gnutls.org/](https://www.gnutls.org/)

## Downloads & Packages

- Development libraries and release archives are published on the GitHub [releases](https://github.com/savoirfairelinux/gnutls/releases) page.
- Available for integration via **vcpkg** for Windows (`windows-x64`, `windows-x86`).

## Building with Visual Studio

Visual Studio solution and project files are located in the `SMP/` directory:
- `SMP/libgnutls.sln`
- Run `SMP/project_get_dependencies.bat` to retrieve dependencies (nettle, gmp, zlib).
- Refer to `SMP/readme.txt` for additional configuration options.

## Issues & Contributing

- For issues and pull requests related to MSVC build support, please use the [issue tracker](https://github.com/savoirfairelinux/gnutls/issues).
- Issues and fixes that apply to upstream GnuTLS should be reported upstream to [GnuTLS GitLab](https://gitlab.com/gnutls/gnutls).

## License

Code authored for MSVC compatibility is licensed under [LGPLv2.1](https://www.gnu.org/licenses/lgpl-2.1.html). All upstream code remains under its original GNU LGPL / GPL license terms.