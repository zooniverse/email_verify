FROM node:4.8-alpine

WORKDIR /app/

COPY package.json /app/

RUN npm ci

COPY . /app/

CMD [ "npm", "start" ]
