# bash 增强（仅 Linux；Fedora 的 ~/.bashrc 会自动加载 ~/.bashrc.d/*）
# 部署：ln -s ~/dotfiles/system/bash/tools.sh ~/.bashrc.d/tools.sh
#       ln -s ~/dotfiles/system/bash/inputrc ~/.inputrc
# 需要：sudo dnf install fzf zoxide eza bat ripgrep；starship 装在 ~/.local/bin（没装时自动跳过，不报错）

# 历史：存更多、去重、每条命令执行完就写盘，多个终端能看到彼此的历史
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F %T  '
shopt -s histappend
PROMPT_COMMAND+=('history -a')

# 输目录名直接 cd；cd 时自动纠正小拼写错误；** 递归匹配
shopt -s autocd cdspell dirspell globstar

# eza：带图标、目录在前的 ls；ll 详细列表（含 git 状态），la 含隐藏文件，lt 树状两层
if command -v eza >/dev/null; then
    alias ls='eza --group-directories-first --icons=auto'
    alias ll='ls -l --git --time-style=relative'
    alias la='ll -a'
    alias lt='ls --tree --level=2'
fi

# bat：cat 带语法高亮（管道里仍是原样输出）；man 页面也用 bat 着色
if command -v bat >/dev/null; then
    alias cat='bat -pp'
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export MANROFFOPT='-c'
fi

# fzf：caps+r 模糊搜历史、caps+t 模糊找文件、alt+c 模糊 cd
if command -v fzf >/dev/null; then
    export FZF_DEFAULT_OPTS='--height 40% --layout reverse --border'
    # 用 ripgrep 列文件：比 find 快，并跳过 .gitignore 里的东西
    if command -v rg >/dev/null; then
        export FZF_DEFAULT_COMMAND="rg --files --hidden --glob '!.git'"
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
    command -v bat >/dev/null && export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {}'"
    command -v eza >/dev/null && export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons=always --color=always {}'"
    eval "$(fzf --bash)"
fi

# zoxide：z 名字 跳到常去的目录，zi 交互选择
if command -v zoxide >/dev/null; then
    eval "$(zoxide init bash)"
fi

# starship 提示符：显示目录、git 分支/状态、上条命令耗时和失败状态（放最后，它要接管 PROMPT_COMMAND）
if command -v starship >/dev/null; then
    eval "$(starship init bash)"
fi
