FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive

ADD package.json /app/

WORKDIR /app

RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y curl supervisor && \
    curl https://deb.nodesource.com/setup | bash - && \
    apt-get install -y nodejs build-essential automake  autoconf && \
    apt-get clean && \
    npm install

ADD ./ /app/
ADD ./supervisor.conf /etc/supervisor/conf.d/email_verify.conf

EXPOSE 80

ENTRYPOINT [ "/usr/bin/supervisord" ]
