#!/bin/sh

EXCLUDES="--exclude=.mypy_cache/ --exclude=.pytest_cache/ --exclude=__pycache__ --exclude=.cache --exclude=.dtrash --exclude=CacheStorage"
rsync -av -n  ${EXCLUDES} /media/dpb/ssd-home/volumes/dpb/Dropbox $HOME
