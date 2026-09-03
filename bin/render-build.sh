#!/usr/bin/env bash
# Render build script for the Gigoo WebMCP hackathon demo.
set -o errexit

bundle install
bundle exec rails assets:precompile
bundle exec rails db:prepare
bundle exec rails db:seed
