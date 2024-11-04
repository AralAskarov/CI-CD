#!/bin/bash

# based on https://docs.gitlab.com/ee/install/installation.html   
# installation gitlab server using the source files. 
# !!!!!!!!!!!!! for Ubuntu/Debian

# 1. Packages and dependencies
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install sudo -y

#build dependencies
sudo apt-get install -y build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libre2-dev \
  libreadline-dev libncurses5-dev libffi-dev curl openssh-server libxml2-dev libxslt-dev \
  libcurl4-openssl-dev libicu-dev libkrb5-dev logrotate rsync python3-docutils pkg-config cmake \
  runit-systemd

#TODO it requires to use 1.1 openssl. by default it installes 3.0. 17.7 requires 3.0, 17.5 requires 1.1

#git should use git version provided by gitaly

sudo apt-get install -y libcurl4-openssl-dev libexpat1-dev gettext libz-dev libssl-dev libpcre2-dev build-essential git-core


#gitaly requires go, gitlab also requires go complier 4. Go (1.22.5)

sudo rm -rf /usr/local/go

curl --remote-name --location --progress-bar "https://go.dev/dl/go1.22.5.linux-amd64.tar.gz"
echo '904b924d435eaea086515bc63235b192ea441bd8c9b198c507e85009e6e4c7f0  go1.22.5.linux-amd64.tar.gz' | shasum -a256 -c - && \
  sudo tar -C /usr/local -xzf go1.22.5.linux-amd64.tar.gz
sudo ln -sf /usr/local/go/bin/{go,gofmt} /usr/local/bin/
rm go1.22.5.linux-amd64.tar.gz


git clone https://gitlab.com/gitlab-org/gitaly.git -b 17-5-stable /tmp/gitaly
cd /tmp/gitaly
sudo make git GIT_PREFIX=/usr/local
#removing system git
sudo apt remove -y git-core
sudo apt autoremove
#TODO in gitlab.yml change git path

#GraphicsMagick + Mail server + ExifTool
sudo apt-get install -y graphicsmagick
sudo apt-get install -y postfix
sudo apt-get install -y libimage-exiftool-perl


echo PZHZFGGZGZGGZG
# 2. Ruby 3.2 requires
sudo apt install autoconf
sudo apt install gperf
sudo apt install bison -y

cd ~
sudo apt install ruby -y # base ruby
git clone https://github.com/ruby/ruby.git ~/ruby 
cd ~/ruby
git checkout ruby_3_2
./autogen.sh
mkdir build && cd build
mkdir ~/.rubies
../configure --prefix="${HOME}/.rubies/ruby-master" --with-baseruby=/usr/bin/ruby
make
sudo make install
sudo apt remove ruby -y
echo 'export PATH="${HOME}/.rubies/ruby-master/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
ruby -v

# 3. Rubygems
gem update --system

cd ~
# 5. Node. 20.x releases and yarn 1.22.x (2 is not supported)
curl --location "https://deb.nodesource.com/setup_20.x" | sudo bash -
sudo apt-get install -y nodejs

sudo npm install --global yarn

# 6. System user for gitlab

cd ~
sudo adduser --disabled-login --gecos 'GitLab' git

# 7. Database postgres 14.x+
cd ~
sudo apt install -y postgresql postgresql-client libpq-dev postgresql-contrib
psql --version
sudo service postgresql start
sudo service postgresql status
sudo -u postgres psql -d template1 -c "CREATE USER git CREATEDB;"
# pg_term. btree_gist, plpsql extensions
sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS btree_gist;"
sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS plpgsql;"

sudo -u postgres psql -d template1 -c "CREATE DATABASE gitlabhq_production OWNER git;"
# check if extensions are enable
sudo -u postgres psql -d gitlabhq_production -c "SELECT true AS enabled FROM pg_available_extensions WHERE name = 'pg_trgm' AND installed_version IS NOT NULL;"
sudo -u postgres psql -d gitlabhq_production -c "SELECT true AS enabled FROM pg_available_extensions WHERE name = 'btree_gist' AND installed_version IS NOT NULL;"
sudo -u postgres psql -d gitlabhq_production -c "SELECT true AS enabled FROM pg_available_extensions WHERE name = 'pgjwt' AND installed_version IS NOT NULL;"

