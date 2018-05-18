#!/usr/bin/env bash

# for debugging
set -eux

# for production
# set -eu


###
# Constantes
############

readonly USER_1000="$(id -nu 1000)"
readonly UBUNTU="xenial"
readonly CODENAME="$(lsb_release -cs)"
readonly ARQ_PROC="$(getconf LONG_BIT)"
readonly DESKTOP="$(env | grep '^DESKTOP_SESSION=' | cut -d= -f2)"

readonly ARDUINO_TAR="$(curl -s https://www.arduino.cc/en/Main/Software | grep -o 'arduino-.\..\..-linux64').tar.xz"
readonly ARDUINO_DIR="$(echo "$ARDUINO_TAR" | grep -o 'arduino-.\..\..')"
readonly ARDUINO_URL="https://downloads.arduino.cc/${ARDUINO_TAR}"
readonly ARDUINO_ICO="/home/$USER_1000/Desktop/arduino-arduinoide.desktop"

readonly KICAD_PPA="ppa:js-reynaud/kicad-4"
readonly KICAD_SRC="js-reynaud-kicad-4-xenial.list"

readonly JAVA_PPA="ppa:webupd8team/java"
readonly JAVA_SRC="webupd8team-java-xenial.list"

readonly VBOX_PPA="deb http://download.virtualbox.org/virtualbox/debian $UBUNTU contrib"

readonly VAGRANT_VER="2.1.1"
readonly VAGRANT_PKG="vagrant_${VAGRANT_VER}_x86_64.deb"
readonly VAGRANT_URL="https://releases.hashicorp.com/vagrant/$VAGRANT_VER/$VAGRANT_PKG"

readonly EPSON_SRC="deb http://download.ebz.epson.net/dsc/op/stable/debian/ lsb3.2 main"

# readonly NVIDIA_PPA="ppa:graphics-drivers/ppa"
# readonly NVIDIA_SRC="graphics-drivers-ubuntu-ppa-xenial.list"

# readonly MINICONDA_SCRIPT="Miniconda3-latest-Linux-x86_64.sh"
# readonly MINICONDA_URL="https://repo.continuum.io/miniconda/$MINICONDA_SCRIPT"

# readonly CHROME_PKG="google-chrome-stable_current_amd64.deb"
# readonly CHROME_URL="https://dl.google.com/linux/direct/$CHROME_PKG"

# readonly SPOTIFY_SRC="spotify.list"


###
# Funções
############

is_superuser()
{
    echo -e "\n###### Verificando superusuário e variáveis de ambiente ######\n"

    if [[ "$(id -u)" -ne 0 ]] || [[ -z "$DESKTOP" ]] || \
        [[ "$(echo "$PATH" | grep -c games)" -eq 0 ]]
    then
        echo "Executar o script como superusuário (sudo)"
        echo "e preservando as variáveis de ambiente (opção -E):"
        echo "\$ sudo -E \"PATH=\$PATH\" ./$(basename "$0")"
        exit 1
    else
        echo "Ok!"
    fi
}

is_linux_mint()
{
    echo -e "\n###### Verificando OS ######\n"

    if [[ "$CODENAME" != "sylvia" ]] || [[ "$DESKTOP" != "cinnamon" ]] || \
        [[ "$ARQ_PROC" -ne 64 ]]
    then
        echo "Script post-install para Linux Mint 18.3 Sylvia 64-bit"
        echo "Versão do sistema incompatível: $CODENAME"
        exit 1
    else
        echo "Ok!"
    fi
}

update_upgrade()
{
    echo -e "\n###### Update & Upgrade ######\n"

    (apt-get update && apt-get -y full-upgrade) || exit 1
}

remove_clean()
{
    echo -e "\n###### Limpando cache ######\n"

    apt-get -y autoremove
    apt-get -y autoclean
    apt-get -y clean
}

install_tools()
{
    echo -e "\n###### Instalando ferramentas de linha de comando ######\n"

    apt-get -y install build-essential cmake \
        p7zip-full p7zip-rar \
        atop iotop iftop glances tree \
        vim-nox git tmux shellcheck
}

enable_firewall()
{
    if [[ "$(ufw status | grep -c inactive)" -ne 0 ]]; then

        echo -e "\n###### Configurando UFW  ######\n"

        ufw default deny incoming
        ufw default allow outgoing
        ufw enable
    fi
}

install_apps()
{
    echo -e "\n###### Instalando aplicativos gráficos ######\n"

    apt-get -y install ubuntu-restricted-extras \
        vlc gimp inkscape mypaint agave \
        openscad openscad-mcad freecad freecad-doc \
        gscan2pdf pdfmod pdfshuffler \
        ttf-mscorefonts-installer fonts-hack-ttf typecatcher \
        nemo-dropbox thunderbird goldendict gelemental \
        meld pyrenamer cryptkeeper
}

install_oracle_java()
{
    if [[ ! -s "/etc/apt/sources.list.d/$JAVA_SRC" ]]; then
        add-apt-repository -y "$JAVA_PPA"
        apt-get update
        echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections
        echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 seen  true" | debconf-set-selections
        apt-get -y install oracle-java8-installer
        echo 0 | update-alternatives --config java
        echo 0 | update-alternatives --config javac
        echo "JAVA_HOME=\"/usr/lib/jvm/java-8-oracle\"" >> /etc/environment
        source /etc/environment
        java -version
        javac -version
        echo "$JAVA_HOME"
    fi
}

install_atom()
{
    echo -e "\n###### Instalando Atom IDE ######\n"

    wget https://atom.io/download/deb -O atom-amd64.deb
    dpkg -i atom-amd64.deb
}

install_arduino()
{
    echo -e "\n###### Instalando Arduino IDE ######\n"

    if [[ ! -s "$ARDUINO_TAR" ]]; then
        sudo -H -u "$USER_1000" wget "$ARDUINO_URL"
        tar -xJf "$ARDUINO_TAR"

        sudo -H -u "$USER_1000" ./"$ARDUINO_DIR"/install.sh
        usermod -a -G dialout "$USER_1000"

        chown "$USER_1000"."$USER_1000" "$ARDUINO_ICO"
        chmod 0755 "$ARDUINO_ICO"

        rm -rf "$ARDUINO_DIR"
    fi
}

install_kicad()
{
    echo -e "\n###### Instalando KiCad ######\n"

    if [[ ! "$(dpkg -l kicad)" ]] && [[ ! -s "$KICAD_SRC" ]]; then
        add-apt-repository -y "$KICAD_PPA"
        apt-get update
        apt-get install kicad
    fi
}

install_lang()
{
    echo -e "\n###### Instalando Pacotes de Idiomas ######\n"

    apt-get -y install language-pack-es language-pack-pt \
        language-pack-gnome-pt language-pack-gnome-es \
        firefox-locale-es firefox-locale-pt \
        thunderbird-locale-en-us thunderbird-locale-es-ar thunderbird-locale-pt-br \
        hunspell-es hunspell-pt-br /
        aspell-es aspell-pt-br
}

install_vm()
{
    if [[ ! "$(dpkg -l virtualbox-5.2)" ]]; then
        echo -e "\n###### Instalando VirtualBox ######\n"

        if [[ "$(grep -c "$VBOX_PPA" /etc/apt/sources.list)" -eq 0 ]]; then
            echo -e "\n# VirtualBox" >> /etc/apt/sources.list
            echo "deb http://download.virtualbox.org/virtualbox/debian xenial contrib" >> /etc/apt/sources.list
            wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
            apt-get -y update
        fi

        apt-get -y install virtualbox-5.2
    fi

    if [[ ! "$(dpkg -l vagrant)" ]]; then
        echo -e "\n###### Instalando Vagrant ######\n"

        if [[ ! -s "./$VAGRANT_PKG" ]]; then
            sudo -H -u "$USER_1000" wget "$VAGRANT_URL"
        fi
        dpkg -i ./"$VAGRANT_PKG"
    fi
}

install_js_stack()
{
    if [[ ! "$(dpkg -l nodejs)" ]]; then
        echo -e "\n###### Instalando Node.js ######\n"

        curl -sSL https://deb.nodesource.com/setup_6.x -o nodesource_setup.sh
        if [[ $? -eq 0 ]]; then
            bash nodesource_setup.sh && apt-get -y install nodejs \
                && npm install npm@latest -g
        else
          echo "Error: Node.js can't been installed!"
        fi
    fi

    if [[ ! "$(dpkg -l mongodb-org)" ]]; then
        echo -e "\n###### Instalando MongoDB ######\n"

        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
        echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
        apt-get update && apt-get install -y mongodb-org
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

install_powerline()
{
    if [[ "$(pip list | grep -c powerline-status)" -eq 0 ]]; then
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
    ubuntu-drivers devices
    ubuntu-drivers autoinstall

    # if [[ ! -s "/etc/apt/sources.list.d/$NVIDIA_SRC" ]]; then
    #     echo -e "\n###### Instalando Nvidia drivers ######\n"

    #     add-apt-repository -y "$NVIDIA_PPA"
    #     apt-get update
    #     ubuntu-drivers devices
    #     ubuntu-drivers autoinstall
    #     apt-get -y install nvidia-390 nvidia-settings nvidia-prime
    # fi
}

install_epson()
{
    if [[ "$(grep -c "$EPSON_SRC" /etc/apt/sources.list)" -eq 0 ]]; then
        echo -e "\n###### Instalando Epson L355 drivers ######\n"

        echo -e "\n# Epson printer\n$EPSON_SRC" >> /etc/apt/sources.list
        apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E5E86C008AA65D56
        apt-get update && apt-get -y install epson-inkjet-printer-201207w
    fi
}

install_spotify()
{
    if [[ "$(grep -c "SPOTIFY_SRC" /etc/apt/sources.list)" -eq 0 ]]; then
        sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys BBEBDCB318AD50EC6865090613B00F1FD2C19886 0DF731E45CE24F27EEEB1450EFDC8610341D9410
        echo deb http://repository.spotify.com stable non-free | sudo tee /etc/apt/sources.list.d/spotify.list
        sudo apt-get update && sudo apt-get install spotify-client
    fi
}

###
#
#   *** INSTRUÇÕES
#   *** Descomentar as categorias que deseja instalar
#
############

is_superuser
is_linux_mint

# enable_firewall
# update_upgrade

# install_tools
# install_apps

    ### devel ###
    # install_oracle_java
    # install_js_stack
    # install_py_stack
    # install_atom
    # install_arduino
    install_kicad
    # install_vm

    ### drivers ###
    # install_nvidia
    # install_epson

# install_powerline
# install_chrome
# install_spotify
# install_lang

# remove_clean

exit 0
