+++
title = 'Vim Plugin Manager'
date = 2024-03-28T12:00:30+08:00
+++

### What is a Vim plugin and why would I need a plugin manager?
> A Vim plugin is a set of Vimscript files that are laid out in a certain directory structure. Before plugin managers became popular, Vim plugins were usually distributed as tarballs. Users would manually download the file and extract it in a single directory called ~/.vim, and Vim would load the files under the directory during startup.
> 
> This simplistic "download & unzip" method might work for a tiny number of plugins but the effectiveness of it degenerates quickly as the number of plugins grows. All the files from different plugins share the same directory structure and you can't easily tell which file is from which plugin of which version. The directory becomes a mess, and it's really hard to update or remove a certain plugin.

### popular plugin managers
There are several popular plugin managers for Vim that can help you manage your Vim plugins. Here are a few:

1. **Vundle (Vim Bundle):** Vundle is a Vim plugin manager that allows you to install, update, and clean up your plugins directly from within Vim. It uses a simple, text-based configuration file to manage your plugins.

    GitHub: <https://github.com/VundleVim/Vundle.vim>

2. **Pathogen:** Pathogen is a minimalist Vim plugin manager. It doesn't have as many features as some other plugin managers, but it's very easy to use and has a low learning curve.

    GitHub: <https://github.com/tpope/vim-pathogen>

3. **vim-plug:** vim-plug is a minimalist Vim plugin manager that supports on-demand loading of plugins and parallel installation/update of plugins. It's very fast and efficient.

    GitHub: <https://github.com/junegunn/vim-plug>

4. **NeoBundle:** NeoBundle is a next-generation Vim plugin manager based on Vundle. It supports parallel installation/update of plugins and has many other advanced features.

    GitHub: <https://github.com/Shougo/neobundle.vim>

5. **Dein.vim:** Dein.vim is a dark powered Vim/Neovim plugin manager by Shougo, the author of NeoBundle. It's faster and has more features compared to NeoBundle.

    GitHub: <https://github.com/Shougo/dein.vim>

Each of these plugin managers has its own strengths and weaknesses, and the best one for you depends on your specific needs and preferences.

### vim-plug
**vim-plug**, a modern Vim plugin manager, downloads plugins into separate directories for you and makes sure that they are loaded correctly. It allows you to easily update the plugins, review (and optionally revert) the changes, and remove the plugins that are no longer used.

vim-plug is a nice alternative to Vundle, it does things a bit different from a technical point of view which should make it faster (see this). It has most (or all?) of the features of Vundle.

- Parallel update procedure for Vim with any of +ruby, +python, or Neovim. Falls back to sequential mode using Vimscript if none is available.
- Lazy loading, for faster startup (see this).
- Install plugins.
- Update plugins.
- Review / rollback updates.
- Supports OSX, Linux & UNIX systems, and MS Windows.
- Post-update hooks e.g. automatically recompile YCM

##### Setting up
vim-plug is distributed as a single Vimscript file. All you have to do is to download the file in a directory so that Vim can load it.
```bash
# Vim (~/.vim/autoload)
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

env: **vim** OS X 

##### Installing plugins
declare the list of plugins you want to use in your Vim configuration file(~/.vimrc for ordinary Vim).
```text
" Plugins will be downloaded under the specified directory.
call plug#begin(has('nvim') ? stdpath('data') . '/plugged' : '~/.vim/plugged')

" Declare the list of plugins.
Plug 'tpope/vim-sensible'
Plug 'junegunn/seoul256.vim'

" List ends here. Plugins become visible to Vim after this call.
call plug#end()
```
After adding the above to the top of your Vim configuration file, reload it (`:source ~/.vimrc`) or restart Vim. Now run `:PlugInstall` to install the plugins.

##### Updating plugins
Run `:PlugUpdate` to update the plugins.After the update is finished, you can review the changes by pressing D in the window. Or you can do it later by running `:PlugDiff`.

##### Reviewing the changes
Updated plugins may have new bugs and no longer work correctly. With `:PlugDiff` command you can review the changes from the last `:PlugUpdate` and roll each plugin back to the previous state before the update by pressing X on each paragraph.

##### Removing plugins
1. Delete or comment out Plug commands for the plugins you want to remove.
2. Reload vimrc (`:source ~/.vimrc`) or restart Vim
3. Run `:PlugClean`. It will detect and remove undeclared plugins.

### Recommend Plugins
1. seoul256.vim

    seoul256.vim is a low-contrast Vim color scheme based on Seoul Colors. 
    <https://github.com/junegunn/seoul256.vim>

2. vim-sensible

    a universal set of defaults that (hopefully) everyone can agree on
    <https://github.com/tpope/vim-sensible>

3. nerdtree
    
    The NERDTree is a file system explorer for the Vim editor.
    <https://github.com/preservim/nerdtree>


#### *reference*: 
<https://github.com/junegunn/vim-plug/wiki/tutorial>
