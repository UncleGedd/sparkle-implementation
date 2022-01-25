set -e

# Bb Quickstart: https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/docs/guides/deployment_scenarios/quickstart.md#step-10-install-big-bang-using-the-local-development-workflow
# From Step 3 in quickstart guide
sudo apt install git -y
sudo apt update -y && sudo apt install apt-transport-https ca-certificates curl gnupg lsb-release -y && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && sudo apt update -y && sudo apt install docker-ce docker-ce-cli containerd.io -y && sudo usermod --append --groups docker $USER

echo "** Exit to allow usermod change to take effect **"
