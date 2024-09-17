#!/usr/bin/bash

## As normal non root user 
sudo apt-get update -y
sudo apt-get install perl gcc make htop wget curl apt-transport-https net-tools moreutils jq htop -y
sudo apt-get install build-essential procps file git -y

## Install docker
#sudo apt-get install docker docker.io -y
sudo apt-get update -y
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

#sudo usermod -aG docker $USER && newgrp docker 
sudo usermod -aG docker $USER 

# Set docker image path to /data/docker
sudo cat <<< $(jq -r '. + { "data-root": "/data/docker" }' /etc/docker/daemon.json) > /etc/docker/daemon.json
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo docker info | grep "Docker Root Dir"

## Install Kubectl
cd ~
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
# Set Executable
chmod +x ./kubectl	
# Move to other binary location
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version -o json 

## Install Krew
cd ~
(
set -x; cd "$(mktemp -d)" &&
OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
KREW="krew-${OS}_${ARCH}" &&
curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
tar zxvf "${KREW}.tar.gz" &&
./"${KREW}" install krew
)
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> ~/.bashrc
kubectl krew version

## Install Brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
test -r ~/.bashrc && echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.bashrc
echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.profile

echo "5 - Install dependencies..."
#Install dependencies
brew install gcc 
brew install k9s
brew install kubernetes-cli
brew install kubectx yq
