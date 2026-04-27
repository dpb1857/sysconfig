#!/bin/sh

EXCLUDES="--exclude=.mypy_cache/ --exclude=.pytest_cache/ --exclude=__pycache__ --exclude=.cache --exclude=.dtrash --exclude=CacheStorage"
rsync -av --delete-after /media/dpb/ssd-home/volumes/dpb/.config/google-chrome $HOME/.config
rsync -av --delete-after ${EXCLUDES} /media/dpb/ssd-home/volumes/dpb/Dropbox $HOME
