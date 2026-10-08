#!/usr/bin/env bash
# Exit on error
set -o errexit

bundle install
npm install
bin/rails assets:precompile
bin/rails assets:clean
bin/rails db:migrate
# Biblioteca común de mantención (db/biblioteca/*.csv). Es idempotente: actualiza por código y no toca datos de las empresas.
bin/rails biblioteca:importar
