#!/bin/bash
# This file is meant to be executed via systemd.
source /usr/local/rvm/scripts/rvm
source /etc/profile.d/rvm.sh
export ruby_ver=$(rvm list default string)

export CONFIGURED=yes
export TIMEOUT=50
export APP_ROOT=/home/rails/gladiabot_stats
export RAILS_ENV="production"
export GEM_HOME="/home/rails/gladiabot_stats/vendor/bundle"
export GEM_PATH="/home/rails/gladiabot_stats/vendor/bundle:/usr/local/rvm/gems/${ruby_ver}:/usr/local/rvm/gems/${ruby_ver}@global"
export PATH="/home/rails/gladiabot_stats/vendor/bundle/bin:/usr/local/rvm/gems/${ruby_ver}/bin:${PATH}"

# Passwords
export SECRET_KEY_BASE=66a8148e12420527ec715fe1984741d956012fe002eaa4ff94cf9c785eeea9067b5ad4461070e60874a4d6bba564649a0f64b5aa2edfc262571871791622d29b
export APP_DATABASE_PASSWORD=601756a617ea1cb6cdee4d4ad56d16b9

# Execute the unicorn process
/home/rails/gladiabot_stats/bin/unicorn -c /etc/unicorn.conf -E production --debug
