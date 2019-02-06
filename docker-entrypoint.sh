#!/usr/bin/env bash
set -e
set -o pipefail

echo "[$1]"

GIT_REMOTE_URL=${GIT_REMOTE_URL//\//\\\/}
GIT_REMOTE_URL=${GIT_REMOTE_URL//@/\\@}

if [ ! -f "_config.yml" ]; then
	printf "\n[Initializing Hexo...]\n\n"
	shopt -s dotglob
	mkdir -p tmp-init
	cd tmp-init
	rm -rf * || :
	hexo init /blog/tmp-init
	cd ..
	mv tmp-init/* ./
	rm -rf tmp-init
	
	printf "\n[Initializing Hexo Deployer and Yuque...]\n\n"
	npm --registry=https://registry.npm.taobao.org install hexo-deployer-git --save

	printf "\n[Configuring hexo directory...]\n"
	sed -r 's/^(\s*)"name"(\s*:\s*)".*"/\1"name"\2"'$HEXO_SITENAME'"/g;$i\,\n  "yuqueConfig": {\n    "baseUrl": "https://www.yuque.com/api/v2",\n    "login": "'$YUQUE_USERLOGIN'",\n    "repo": "'$YUQUE_REPO'",\n    "mdNameFormat": "slug",\n    "postPath": "source/_posts/yuque"\n  },\n  "scripts": {\n    "sync-gen": "echo [yuque-hexo clean] && yuque-hexo clean && echo [yuque-hexo sync] && yuque-hexo sync && echo [git add and commit] && git add . && git commit -am \\\"`date`\\\" && echo [hexo g] ; hexo g && echo [chown] && chown --reference=. . -R && echo [chown root] && chown root:root .git-credentials ; chown root:root .ssh -R",\n    "sync-gen-deploy": "echo [yuque-hexo clean] && yuque-hexo clean && echo [yuque-hexo sync] && yuque-hexo sync && echo [git add and commit] && git add . && git commit -am \\\"`date`\\\" && echo [chown] && chown --reference=. . -R && echo [chown root] &&  echo [hexo g -d] && hexo g -d && chown root:root .git-credentials ; chown root:root .ssh -R"\n  }' -i package.json
	perl -0777 -i.backup -pe 's/deploy:(\s*)\n(\s*)type:([ \t]+[^\n]*\n)*/deploy:\1\n\2type: git\n\2repository: '$GIT_REMOTE_URL'\n\2branch: '$GIT_DEPLOY_BRANCH'\n\n/g' _config.yml

	echo "" >> .gitignore	
	echo ".ssh/" >> .gitignore
	echo ".git-credentials" >> .gitignore

	git config --global user.email "${GIT_USER_EMAIL:-gituser@git-scm.com}"
        git config --global user.name "${GIT_USER_NAME:-gituser}"
	git init
	git add .
	git status
	git commit -am "First commit @ `date`"
	chown --reference=. . -R
fi

if [ $YUQUE_WEBHOOK_AUTODEPLOY ]; then
	printf "\n[Configuring git...]\n\n"
	git config --global user.email "${GIT_USER_EMAIL:-gituser@git-scm.com}"
        git config --global user.name "${GIT_USER_NAME:-gituser}"
	git config --global credential.helper store
	touch /blog/.git-credentials
	chmod 600 /blog/.git-credentials
	chown root:root /blog/.git-credentials
	
	ln -svf /blog/.git-credentials /root/.git-credentials
	
	if [ ! -f ./.ssh/id_rsa ] || [ ! -f ./.ssh/id_rsa.pub ] ; then
		mkdir -p ./.ssh/
		rm -rf ~/.ssh
		ln -sfv /blog/.ssh /root/
		ssh-keyscan github.com >> ~/.ssh/known_hosts
		ssh-keygen -b 4096 -t rsa -C "hexo" -f ./.ssh/id_rsa -N ""
		chown root:root ./.ssh/*
		chown root:root ./.ssh
		chmod 600 ./.ssh/*
		chmod 700 ./.ssh

		printf "\n****** Your git ssh public key ******\n"
		printf "\n***** Copy it to the git server *****\n"
		cat /blog/.ssh/id_rsa.pub
		echo "Press Enter to continue"
		read
	else
		printf "\nYour git ssh public key:\n"
		cat /blog/.ssh/id_rsa.pub
	fi
fi

case ${1} in
    start)
	printf "\n[Executing first sync...]\n"
	if [ ${YUQUE_WEBHOOK_AUTODEPLOY:-0} ]; then
		DEPLOY=sync-gen-deploy
	else
		DEPLOY=sync-gen
	fi
	sh -c "cd /blog ; npm run $DEPLOY"
        printf "\n[Starting Webhook server...]\n"
        node /usr/bin/yuque-webhook.js
        ;;
        
    *)
        exec "$@"
        ;;
esac

exit 0

