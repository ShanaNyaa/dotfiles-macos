# ~/.zshenv — loaded for EVERY zsh invocation (interactive, scripts, subshells, cron)
# Keep this file fast and side-effect-free: env vars and PATH only.

# --- XDG Base Directory spec ---
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# --- Homebrew ---
if type brew &>/dev/null; then
  export HOMEBREW_PREFIX="$(brew --prefix)"
  FPATH="$HOMEBREW_PREFIX/share/zsh/site-functions:${FPATH}"
fi

# --- NVM ---
export NVM_DIR="$XDG_DATA_HOME/nvm"

# --- LM Studio ---
export PATH="$PATH:/Users/shana/.lmstudio/bin"

# --- Postman ---
export PATH='/Users/shana/.local/bin':"$PATH"

# --- GPG ---
export GPG_TTY=$(tty)

# --- Editor and pager ---
export EDITOR="nvim"
export VISUAL="nvim"
export MANPAGER="nvim +Man!"

# --- Zsh history (XDG_STATE_HOME, since history is log-like state) ---
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export HISTSIZE=10000
export SAVEHIST=10000
