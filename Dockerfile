FROM node:latest

ENV HEXO_SITENAME hexo-site
ENV YUQUE_USERLOGIN yuqueuser
ENV YUQUE_REPO yuquerepo
ENV YUQUE_WEBHOOK_PORT 32125
ENV YUQUE_WEBHOOK_LISTENADDR "0.0.0.0"
ENV GIT_USER_EMAIL gituser@email.org
ENV GIT_USER_NAME "Git User"
ENV GIT_REMOTE_URL "https://github.com/username/repository"
ENV GIT_DEPLOY_BRANCH master
ENV YUQUE_WEBHOOK_AUTODEPLOY 0
ENV TZ "Asia/Shanghai"

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

WORKDIR /blog

RUN npm --registry=https://registry.npm.taobao.org install hexo-cli hexo-server yuque-hexo -g

COPY docker-entrypoint.sh yuque-webhook.js /usr/bin/
RUN chmod +x /usr/bin/docker-entrypoint.sh && ln -sfv /blog/.ssh /root/

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["start"]

EXPOSE $YUQUE_WEBHOOK_PORT

VOLUME ["/blog"]



