FROM carpool/backend

# REQUIRED ENV PROVIDED BY DOCKER COMPOSE RUN
ENV PGDATABASE=LIVE

WORKDIR /matchingEngine

RUN npm install

ENTRYPOINT ["npm", "start"]
