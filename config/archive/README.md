# Dotfiles

Jon's dotfiles synced a bare repo on [this branch](https://github.com/suderman/dotfiles/tree/dotfiles).

## Quick Start

Clone to `~/.cfg` as a bare repo and checkout the `dotfiles` branch with `$HOME` set as the work tree. 

```
git clone --bare https://github.com/suderman/dotfiles.git ~/.cfg
git --git-dir=$HOME/.cfg config --local status.showUntrackedFiles no
git --git-dir=$HOME/.cfg --work-tree=$HOME checkout dotfiles
```

## Additional setup

```
sudo pacman -S --needed base-devel git fzf tree bat
```

### AUR helper

```
mkdir -p ~/.cache/git
git clone https://aur.archlinux.org/paru.git ~/.cache/git/paru
cd ~/.cache/git/paru
makepkg -si
```

## AUR Packages via paru

```
paru -S lf delta
```

### Persist Git credentials

```
git config --global credential.helper store
```

### zsh plugins

```
git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
git clone https://github.com/kazhala/dotbare.git ~/.oh-my-zsh/custom/plugins/dotbare
```

### nvim plugins

```
mkdir -p ~/.local/share/nvim/site/autoload
curl -fL https://github.com/junegunn/vim-plug/raw/master/plug.vim > ~/.local/share/nvim/site/autoload/plug.vim
nvim -c PlugInstall
```

### tmux plugins

```
mkdir -p ~/.local/share/tmux/plugins
git clone https://github.com/tmux-plugins/tpm ~/.local/share/tmux/plugins/tpm
```
