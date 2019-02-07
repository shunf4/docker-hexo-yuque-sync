#!/usr/bin/env bash
set -e
set -o pipefail

echo "[$1]"

GIT_REMOTE_URL=${GIT_REMOTE_URL//\//\\\/}
GIT_REMOTE_URL=${GIT_REMOTE_URL//@/\\@}

case ${1} in
    start)
		if [ ! -f "_config.yml" ]; then
			printf "\n[Initializing Hexo...]\n\n"

			if [ ! -d "/usr/share/blog-skel" ] || [ -z "$(ls -A /usr/share/blog-skel)" ]; then
				echo "Error! /usr/share/blog-skel does not appear to be a valid hexo skeleton directory. Maybe this container has already initialized a volume before. Try running a new container."
				exit 1
			fi

			shopt -s dotglob
			mv /usr/share/blog-skel/* ./
			rm -rf /usr/share/blog-skel

			printf "\n[Configuring hexo directory...]\n"
			sed -r 's/^(\s*)"name"(\s*:\s*)".*"/\1"name"\2"'$HEXO_SITENAME'"/g;$i\,\n  "yuqueConfig": {\n    "baseUrl": "https://www.yuque.com/api/v2",\n    "login": "'$YUQUE_USERLOGIN'",\n    "repo": "'$YUQUE_REPO'",\n    "mdNameFormat": "slug",\n    "postPath": "source/_posts/yuque"\n  },\n  "scripts": {\n    "sync-gen": "/usr/bin/sync-gen.sh",\n    "sync-gen-deploy": "/usr/bin/sync-gen-deploy.sh"\n  }' -i package.json
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

		git config --local receive.denyCurrentBranch updateInstead

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

				printf "\nYour git ssh public key:\n"
				cat /blog/.ssh/id_rsa.pub
			fi
		fi

		printf "\n[Executing first sync...]\n"
		if [ $YUQUE_WEBHOOK_AUTODEPLOY ]; then
			DEPLOY=sync-gen-deploy
		else
			DEPLOY=sync-gen
		fi

		if ! npm run $DEPLOY; then
			printf "\n****** Your git ssh public key ******\n"
			printf "\n***** Copy it to the git server *****\n"
			cat /blog/.ssh/id_rsa.pub
			echo "Press Enter to continue"
			read

			npm run $DEPLOY
		fi

		# Again
		npm run $DEPLOY

        printf "\n[Starting Webhook server...]\n"
        node /usr/bin/yuque-webhook.js
        ;;
        
    *)
        exec "$@"
        ;;
esac

exit 0

