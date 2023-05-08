REM= <<WINDOWS_BAT
ECHO WINDOWS

REM RUN WSL
SET LNXPATH=0
SET WINPATH=%~0
FOR /F "usebackq delims=" %%A IN (`wsl wslpath -u %WINPATH:\=/%`) DO SET LNXPATH=%%A

REM wslが有効化されていない場合
if "%LNXPATH%"=="0" (
  
  REM wsl有効化
  dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
  
  REM 仮想マシン プラットフォームオプション機能の有効化
  dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
  
  REM wsl2 に設定
  wsl --set-default-version 2
  
  REM 再起動
  shutdown -r -t 0
)

REM dockerセットアップ
wsl -e bash %LNXPATH%

GOTO EOF
WINDOWS_BAT

echo wsl

cat << CONF > /tmp/wsl.conf
[automount]
enabled = true
root = /mnt/
options = "metadata,uid=1000,gid=1000,umask=022,fmask=11,case=off"
mountFsTab = true
[network]
generateHosts = false
generateResolvConf = false
[interop]
enabled = false
appendWindowsPath = false
[boot]
command = service docker start
CONF

sudo apt update
sudo apt upgrade -y
sudo apt install ca-certificates -y
sudo apt install curl -y
sudo apt install gnupg -y
sudo apt install lsb-release -y
sudo apt install apt-transport-https -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt install docker-ce -y
sudo apt install docker-ce-cli -y
sudo apt install containerd.io -y
sudo usermod -aG docker $USER

DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.3.3/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose

DOCKER_START_PATH=${HOME}/bin
DOCKER_START_FILE=${DOCKER_START_PATH}/DOCKER_START.sh
mkdir ${DOCKER_START_PATH}

if grep "bash ${DOCKER_START_PATH}" ~/.bashrc >/dev/null; then
    echo PASS
else
    sudo echo "bash ${DOCKER_START_FILE}" >> ~/.bashrc
    sudo cat << 'LOGONSCRIPT' > ${DOCKER_START_FILE}
    if test $(service docker status | awk '{print $4}') = 'not'; then
        sudo /usr/sbin/service docker start
    fi
    LOGONSCRIPT
    source ~/.bashrc
fi
exit
