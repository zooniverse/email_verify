FROM node:4-alpine

WORKDIR /app/

COPY package.json /app/

RUN npm install

COPY . /app/

RUN ln -s /run/secrets/database.yml /app/database.yml
RUN ln -s /run/secrets/auth.yml /app/auth.yml

CMD [ "npm", "start" ]
