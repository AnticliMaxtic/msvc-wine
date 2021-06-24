ARG BASE_IMAGE='registry.2020.dev/2020/k8s/pde:user'
FROM ${BASE_IMAGE}

# Ubuntu 20.04 (currently?) requires a separate apt-get upgrade first before
# installing libc6:i386, otherwise that package fails to install.
RUN sudo apt-get update && \
    sudo apt-get upgrade -y && \
    sudo dpkg --add-architecture i386 && \
    sudo apt-get update && \
    sudo apt-get install -y wine-development python msitools python-simplejson \
                       python-six ca-certificates && \
    sudo apt-get clean -y && \
    sudo rm -rf /var/lib/apt/lists/*

WORKDIR /opt/msvc

COPY lowercase fixinclude install.sh vsdownload.py ./
COPY wrappers/* ./wrappers/

RUN \
sudo chown -R ${USERNAME}:${USERNAME} . &&\
PYTHONUNBUFFERED=1 ./vsdownload.py --accept-license --dest /opt/msvc && \
    ./install.sh /opt/msvc && \
    rm lowercase fixinclude install.sh vsdownload.py && \
    rm -rf wrappers

RUN sudo apt-get update && \
    sudo apt-get upgrade -y && \
    sudo apt-get install -y \
        winbind && \
    sudo apt-get clean -y && \
    sudo rm -rf /var/lib/apt/lists/*


# Initialize the wine environment. Wait until the wineserver process has
# exited before closing the session, to avoid corrupting the wine prefix.
RUN wine wineboot --init && \
    while pgrep wineserver > /dev/null; do sleep 1; done

WORKDIR /home/${USERNAME}
# Later stages which actually uses MSVC can ideally start a persistent
# wine server like this:
#RUN wineserver -p && \
#    wine wineboot && \
