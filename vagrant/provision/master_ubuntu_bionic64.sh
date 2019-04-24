echo "==> Installing missing master dependencies"
apt-get update
mkdir -p /etc/salt/{minion.d,master.d}/
cp /vagrant/templates/etc/master.d/overrides.conf.local /etc/salt/master.d/overrides.conf
cp /vagrant/templates/etc/minion.d/overrides.conf.local /etc/salt/minion.d/overrides.conf
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
echo "master: ${1}100" | tee /etc/salt/minion.d/master.conf
apt-get -y install python3 python3-pip python-setuptools git
pip3 install pipenv==2018.11.26

