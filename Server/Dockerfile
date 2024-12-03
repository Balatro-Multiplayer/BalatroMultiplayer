FROM node:21

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

EXPOSE 8788

CMD [ "node", "dist/main.js" ]
