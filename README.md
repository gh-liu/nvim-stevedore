# `nvim-stevedore`

Manage your containers in Neovim.

## ✨ Features

- Interact with images
- Interact with containers
- Edit your image/container like a normal Neovim buffer, same as [oil.nvim](https://github.com/stevearc/oil.nvim)
- Support `podman` and `docker`

## ⚡️ Requirements

- runtime: [docker](https://docs.docker.com) or [podman](https://docs.podman.io)

## Default Keymaps

All most keymaps prefix with `co`(mnemonic: [co]ntainer).

| Binding | Action                                          |
| ------- | -------                                         |
| `<cr>`  | List containers of the image under cursor.      |
| `K`     | Print info of the image/container under cursor. |
| `coi`   | Inspect the image/container under cursor.       |
| `cor`   | Run the image under cursor interactively.       |
| `coR`   | Run the image under cursor in the background.   |
| `cod`   | Delete image under cursor.                      |
| `coD`   | Force delete image under cursor.                |
| `coa`   | Attach container under cursor.                  |
| `cos`   | Start container under cursor interactively.     |
| `coS`   | Start container under cursor.                   |
| `coq`   | Stop container under cursor.                    |
| `cod`   | Delete containers under cursor.                 |
| `col`   | Tail logs container under cursor.               |

## User Command

`Stevedore`: list all images.

