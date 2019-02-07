FROM node:latest

ARG HEXO_SITENAME="hexo blog"
ENV HEXO_SITENAME $HEXO_SITENAME

ARG YUQUE_USERLOGIN=yuqueuser
ENV YUQUE_USERLOGIN $YUQUE_USERLOGIN

ARG YUQUE_REPO=yuquerepo
ENV YUQUE_REPO $YUQUE_REPO

ARG YUQUE_WEBHOOK_PORT=32125
ENV YUQUE_WEBHOOK_PORT $YUQUE_WEBHOOK_PORT

ARG YUQUE_WEBHOOK_LISTENADDR="0.0.0.0"
ENV YUQUE_WEBHOOK_LISTENADDR $YUQUE_WEBHOOK_LISTENADDR

ARG GIT_USER_EMAIL=gituser@email.org
ENV GIT_USER_EMAIL $GIT_USER_EMAIL

ARG GIT_USER_NAME="Git User"
ENV GIT_USER_NAME $GIT_USER_NAME

ARG GIT_REMOTE_URL="https://github.com/username/repository"
ENV GIT_REMOTE_URL $GIT_REMOTE_URL

ARG GIT_DEPLOY_BRANCH=master
ENV GIT_DEPLOY_BRANCH $GIT_DEPLOY_BRANCH

ARG YUQUE_WEBHOOK_AUTODEPLOY=0
ENV YUQUE_WEBHOOK_AUTODEPLOY $YUQUE_WEBHOOK_AUTODEPLOY

ARG TZ="Asia/Shanghai"
ARG GIT_HTTP_PROXY

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

WORKDIR /blog

RUN npm --registry=https://registry.npm.taobao.org install hexo-cli hexo-server yuque-hexo -g

RUN mkdir -p /usr/share/blog-skel ; cd /usr/share/blog-skel && npm config set registry https://registry.npm.taobao.org && git config --global https.proxy $GIT_HTTP_PROXY ; echo Git HTTPS proxy: `git config --global https.proxy` ; echo && echo [hexo init] && echo && hexo init && echo && echo [Install hexo-deployer-git] && echo && npm --registry=https://registry.npm.taobao.org install hexo-deployer-git --save

COPY docker-entrypoint.sh yuque-webhook.js sync-gen.sh sync-gen-deploy.sh /usr/bin/
RUN chmod +x /usr/bin/docker-entrypoint.sh /usr/bin/sync-gen.sh /usr/bin/sync-gen-deploy.sh && ln -sfv /blog/.ssh /root/

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["start"]

EXPOSE $YUQUE_WEBHOOK_PORT

VOLUME ["/blog"]



