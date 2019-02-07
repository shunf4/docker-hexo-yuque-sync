#!/bin/bash
set -e

echo
echo [yuque-hexo clean]
echo
yuque-hexo clean

echo
echo [yuque-hexo sync]
echo
yuque-hexo sync

echo
echo [git add and commit]
echo
git add .
git commit -am "`date`" || :

echo
echo [hexo g]
echo 
hexo g

echo
echo [chown]
echo
shopt -s dotglob
for f in ./* ; do
    if [ $f != "./node_modules" ]; then
        chown --reference=. $f -R
    fi
done


echo
echo [chown root]
echo
chown root:root .git-credentials || :
chown root:root .ssh -R || :