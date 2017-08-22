#!/usr/bin/env bash

set -eux


###
# Constantes
######

readonly CODENAME="$(lsb_release -cs)"
readonly DESK_ENV="$(env | grep DESKTOP_SESSION= | cut -d'=' -f2)"
readonly ARQ_PROC="$(getconf LONG_BIT)"

readonly NVIDIA_PPA="ppa:graphics-drivers/ppa"
readonly NVIDIA_SRC="/etc/apt/sources.list.d/graphics-drivers-ubuntu-ppa-xenial.list"

readonly MINICONDA_SCRIPT="Miniconda3-latest-Linux-x86_64.sh"
readonly MINICONDA_URL="https://repo.continuum.io/miniconda/$MINICONDA_SCRIPT"


###
# Funções
######

is_superuser()
{
    if [[ "$(id -u)" -ne 0 ]] || \                                      # check sudo
        [[ -z "$DESK_ENV" ]] || \                                       # check -E
        [[ ! "$(echo $PATH | grep -o games)" ]]                         # check $PATH
    then
        echo "Executar o script como superusuário (sudo)"
        echo "e preservando as variáveis de ambiente (opção -E):"
        echo "\$ sudo -E \"PATH=\$PATH\" ./$(basename $0)"
        exit 1
    fi
}

is_ubuntu_gnome_64()
{
    if [[ "$CODENAME" != "xenial" ]] || [[ "$DESK_ENV" != "gnome" ]] || \
        [[ "$ARQ_PROC" -ne 64 ]]
    then
        echo "Script post-install para Ubuntu Gnome 16.04 LTS 64-bit"
        echo "Versão do sistema incompatível"
        exit 1
    fi
}

update_upgrade()
{
    apt-get update
    apt-get -y dist-upgrade
}

remove_clean()
{
    apt-get -y autoremove
    apt-get -y autoclean
    apt-get -y clean
}

install_base()
{
    apt-get -y install ubuntu-restricted-extras
}

install_nvidia()
{
    if [[ ! -s "$NVIDIA_SRC" ]]; then
        add-apt-repository -y "$NVIDIA_PPA"
        apt-get update
    fi
}

install_tools()
{
    apt-get -y install vim-nox git tmux tree iotop glances curl build-essential
}

install_apps()
{
    apt-get -y install vlc goldendict meld pyrenamer gimp inkscape mypaint nautilus-dropbox
}

install_js_stack()
{
    # Node.js
    if [[ ! "$(dpkg -l nodejs)" ]]; then
        curl -sSL https://deb.nodesource.com/setup_6.x -o nodesource_setup.sh
        bash nodesource_setup.sh
        apt-get -y install nodejs
        npm install npm@latest -g
    fi

    # MongoDB
    if [[ ! "$(dpkg -l mongodb-org)" ]]; then
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
        echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
        apt-get update
        apt-get install -y mongodb-org
    fi
}

install_py_stack()
{
    # Miniconda
    if [[ ! "$(conda --version)" ]]; then
        if [[ ! -s "./$MINICONDA_SCRIPT" ]]; then
            wget "$MINICONDA_URL"
        fi
        bash "$MINICONDA_SCRIPT"
    fi
    conda update conda
}


###
# Parte principal do script
######

is_superuser
is_ubuntu_gnome_64

update_upgrade

install_base
install_nvidia
install_tools
install_apps

install_js_stack
install_py_stack

remove_clean

