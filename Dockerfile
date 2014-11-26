
FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive

ADD package.json /app/

WORKDIR /app

RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y curl && \
    curl https://deb.nodesource.com/setup | bash - && \
    apt-get install -y nodejs build-essential automake  autoconf && \
    apt-get clean && \
    npm install

ADD ./ /app/

ENTRYPOINT [ "./start.sh" ]
