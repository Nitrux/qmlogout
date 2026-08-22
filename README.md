# QMLogout | [![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

QMLogout is a native QML logout menu for Wayland environments.

![QMLogout](https://nxos.org/wp-content/uploads/2026/08/screenshot-20260822-172247.png)
> QMLogout is a native QML logout menu for Wayland environments.

# Introduction

QMLogout is a lightweight Wayland session management menu for Nitrux OS. It provides a focused MauiKit interface for selecting session actions while running as a LayerShell-Qt overlay.

> [!WARNING]
> QMLogout does not support X11. QMLogout's main target is Nitrux OS, and using it in other distributions is not within its scope. Please do not open issues regarding this use case; they will be closed.

## Features

- Wayland overlay integration through LayerShell-Qt.
- Session actions for logout, lock, reboot, suspend, hibernate, and shutdown.
- MauiKit-based interface with keyboard navigation, hover selection, and configurable countdown activation.
- Configurable overlay opacity, timeout, avatar image, uptime visibility, and icon mode.
- Support for system icons and Nerd Font symbols.
- DPI-aware icon and avatar sizing.


### Runtime Requirements

```
mauikit (>= 4.0.3)
layer-shell-qt
qt6 (>= 6.9.2)
qt6-wayland (>= 6.9.2)
wayland
```

# Licensing

The license for this repository and its contents is **BSD-3-Clause**.

# Issues

If you find problems with the contents of this repository, please create an issue and use the **🐞 Bug report** template.

## Submitting a bug report

Before submitting a bug, you should look at the [existing bug reports](https://github.com/Nitrux/qmlogout/issues) to verify that no one has reported the bug already.

©2026 Nitrux Latinoamericana S.C.
