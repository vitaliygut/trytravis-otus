#!/bin/bash
sudo apt -y  install git
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
systemctl start puma
systemctl enable puma
