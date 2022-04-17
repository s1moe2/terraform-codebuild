FROM node:16-alpine

WORKDIR /usr/src/app
COPY package*.json ./
COPY . .

RUN npm install --only=prod

EXPOSE 3000
USER node
CMD ["node", "index.js"]