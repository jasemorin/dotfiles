# bash 增强（仅 Linux；Fedora 的 ~/.bashrc 会自动加载 ~/.bashrc.d/*）
# 部署：ln -s ~/dotfiles/system/bash/tools.sh ~/.bashrc.d/tools.sh
# 需要：sudo dnf install fzf zoxide（没装时自动跳过，不报错）

# fzf：caps+r 模糊搜历史、caps+t 模糊找文件、alt+c 模糊 cd
if command -v fzf >/dev/null; then
    eval "$(fzf --bash)"
fi

# zoxide：z 名字 跳到常去的目录，zi 交互选择
if command -v zoxide >/dev/null; then
    eval "$(zoxide init bash)"
fi
