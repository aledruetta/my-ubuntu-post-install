#!/usr/bin/env bash

# descomentar para debugging
# set -eux
set -eu


###
# Constantes
############

readonly CODENAME="$(lsb_release -cs)"
readonly DESK_ENV="$(env | grep DESKTOP_SESSION= | cut -d'=' -f2)"
readonly ARQ_PROC="$(getconf LONG_BIT)"

readonly NVIDIA_PPA="ppa:graphics-drivers/ppa"
readonly NVIDIA_SRC="graphics-drivers-ubuntu-ppa-xenial.list"

readonly MINICONDA_SCRIPT="Miniconda3-latest-Linux-x86_64.sh"
readonly MINICONDA_URL="https://repo.continuum.io/miniconda/$MINICONDA_SCRIPT"

readonly VBOX_PPA="deb http://download.virtualbox.org/virtualbox/debian xenial contrib"

readonly VAGRANT_PKG="vagrant_1.9.7_x86_64.deb"
readonly VAGRANT_URL="https://releases.hashicorp.com/vagrant/1.9.7/$VAGRANT_PKG"

readonly CHROME_PKG="google-chrome-stable_current_amd64.deb"
readonly CHROME_URL="https://dl.google.com/linux/direct/$CHROME_PKG"

readonly PAPIRUS_SRC="papirus-ubuntu-papirus-xenial.list"
readonly PAPIRUS_PPA="ppa:papirus/papirus"

readonly NUMIX_SRC="numix-ubuntu-ppa-xenial.list"
readonly NUMIX_PPA="ppa:numix/ppa"

readonly EPSON_SRC="deb http://download.ebz.epson.net/dsc/op/stable/debian/ lsb3.2 main"


###
# Funções
############

is_superuser()
{
    echo -e "\n###### Verificando superusuário e variáveis de ambiente ######\n"

    if [[ "$(id -u)" -ne 0 ]] || [[ -z "$DESK_ENV" ]] || \
        [[ ! "$(echo "$PATH" | grep -o games)" ]]
    then
        echo "Executar o script como superusuário (sudo)"
        echo "e preservando as variáveis de ambiente (opção -E):"
        echo "\$ sudo -E \"PATH=\$PATH\" ./$(basename "$0")"
        exit 1
    else
        echo "Ok!"
    fi
}

is_ubuntu_gnome_64()
{
    echo -e "\n###### Verificando OS ######\n"

    if [[ "$CODENAME" != "xenial" ]] || [[ "$DESK_ENV" != "gnome" ]] || \
        [[ "$ARQ_PROC" -ne 64 ]]
    then
        echo "Script post-install para Ubuntu Gnome 16.04 LTS 64-bit"
        echo "Versão do sistema incompatível"
        exit 1
    else
        echo "Ok!"
    fi
}

update_upgrade()
{
    echo -e "\n###### Update & Upgrade ######\n"

    apt-get update
    apt-get -y dist-upgrade
}

remove_clean()
{
    echo -e "\n###### Limpando cache ######\n"

    apt-get -y autoremove
    apt-get -y autoclean
    apt-get -y clean
}

install_base()
{
    echo -e "\n###### Instalando pacotes de base ######\n"

    apt-get -y install ubuntu-restricted-extras build-essential dkms intel-microcode \
        linux-firmware cmake
}

install_tools()
{
    echo -e "\n###### Instalando ferramentas de linha de comando ######\n"

    apt-get -y install tree iotop glances curl synaptic ufw p7zip-full \
        p7zip-rar

    if [[ "$(ufw status | grep inactive)" ]]; then

        echo -e "\n###### Configurando UFW  ######\n"

        ufw default deny incoming
        ufw default allow outgoing
        ufw enable
    fi
}

install_apps()
{
    echo -e "\n###### Instalando aplicativos gráficos ######\n"

    apt-get -y install vlc goldendict meld pyrenamer gimp inkscape mypaint nautilus-dropbox \
        thunderbird geogebra gelemental agave typecatcher gconf-editor gscan2pdf pdfmod \
        pdfshuffler
}

install_devel()
{
    echo -e "\n###### Instalando development tools ######\n"

    apt-get -y install vim-nox git tmux shellcheck openjdk-8-jdk

    echo -e "\n###### Instalando Atom ######\n"

    snap install atom --classic
}

install_lang()
{
    apt-get -y install  language-pack-es language-pack-pt firefox-locale-es \
        firefox-locale-pt thunderbird-locale-en-us thunderbird-locale-es-ar \
        thunderbird-locale-pt-br hunspell-es hunspell-pt-br aspell-es \
        aspell-pt-br
}

install_vm()
{
    if [[ ! "$(dpkg -l virtualbox-5.1)" ]]; then
        echo -e "\n###### Instalando VirtualBox ######\n"

        if [[ ! "$(grep "$VBOX_PPA" /etc/apt/sources.list)" ]]; then
            echo -e "\n# VirtualBox" >> /etc/apt/sources.list
            echo "deb http://download.virtualbox.org/virtualbox/debian xenial contrib" >> /etc/apt/sources.list
            wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
            apt-get -y update
        fi

        apt-get -y install virtualbox-5.1
    fi

    if [[ ! "$(dpkg -l vagrant)" ]]; then
        echo -e "\n###### Instalando Vagrant ######\n"

        if [[ ! -s "./$VAGRANT_PKG" ]]; then
            wget "$VAGRANT_URL"
        fi
        dpkg -i ./"$VAGRANT_PKG"
    fi
}

install_js_stack()
{
    if [[ ! "$(dpkg -l nodejs)" ]]; then
        echo -e "\n###### Instalando Node.js ######\n"

        curl -sSL https://deb.nodesource.com/setup_6.x -o nodesource_setup.sh
        bash nodesource_setup.sh
        apt-get -y install nodejs
        npm install npm@latest -g
    fi

    if [[ ! "$(dpkg -l mongodb-org)" ]]; then
        echo -e "\n###### Instalando MongoDB ######\n"

        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
        echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
        apt-get update
        apt-get install -y mongodb-org
    fi
}

install_py_stack()
{
    if [[ ! "$(conda --version)" ]]; then
        if [[ ! -s "./$MINICONDA_SCRIPT" ]]; then
            wget "$MINICONDA_URL"
        fi

        echo -e "\n###### Instalando Miniconda ######\n"

        bash "$MINICONDA_SCRIPT"
    fi
    conda update conda
}

install_chrome()
{
    if [[ ! "$(google-chrome --version)" ]]; then
        echo -e "\n###### Instalando Google Chrome ######\n"

        if [[ ! -s "./$CHROME_PKG" ]]; then
            wget "$CHROME_URL"
        fi
        dpkg -i ./"$CHROME_PKG"
    fi
}

install_themes()
{
    if [[ ! -s "/etc/apt/sources.list.d/$PAPIRUS_SRC" ]]; then
        echo -e "\n###### Instalando Papirus Icon Theme ######\n"

        add-apt-repository -y "$PAPIRUS_PPA"
        apt-get update
        apt-get -y install papirus-icon-theme
    fi

    if [[ ! -s "/etc/apt/sources.list.d/$NUMIX_SRC" ]]; then
        echo -e "\n###### Instalando Numix Theme ######\n"

        add-apt-repository -y "$NUMIX_PPA"
        apt-get update
        apt-get -y install numix-icon-theme numix-gtk-theme numix-folders
    fi
}

install_powerline()
{
    if [[ ! "$(pip list | grep powerline-status)" ]]; then
        echo -e "\n###### Instalando Powerline ######\n"

        pip install powerline-status psutil

        wget https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf
        wget https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf
        mv PowerlineSymbols.otf ~/.local/share/fonts/
        fc-cache -vf ~/.local/share/fonts/
        mkdir -p "$HOME/.config/fontconfig/conf.d/"
        mv 10-powerline-symbols.conf ~/.config/fontconfig/conf.d/
    fi
}

install_nvidia()
{
    if [[ ! -s "/etc/apt/sources.list.d/$NVIDIA_SRC" ]]; then
        echo -e "\n###### Instalando Nvidia drivers ######\n"

        add-apt-repository -y "$NVIDIA_PPA"
        apt-get update
        apt-get install nvidia-378 nvidia-opencl-icd-378 nvidia-prime nvidia-settings
    fi
}

install_epson()
{
    if [[ ! "$(grep "$EPSON_SRC" /etc/apt/sources.list)" ]]; then
        echo -e "\n###### Instalando Epson drivers ######\n"

        echo -e "\n# Epson printer\n$EPSON_SRC" >> /etc/apt/sources.list
        apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E5E86C008AA65D56
        apt-get update
        apt-get -y --allow-unauthenticated install epson-inkjet-printer-201207w
    fi
}


###
#
#   *** INSTRUÇÕES
#   *** Descomentar as categorias que deseja instalar
#
############

is_superuser
is_ubuntu_gnome_64

update_upgrade

# install_base
# install_tools
# install_apps
# install_devel
# install_lang

# install_vm
# install_js_stack
# install_py_stack
# install_chrome
# install_themes
# install_powerline
# install_nvidia
# install_epson

remove_clean
