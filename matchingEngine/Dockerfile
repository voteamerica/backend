FROM carpool/backend

# REQUIRED ARG PROVIDED BY DOCKER COMPOSE RUN
ARG PGDATABASE=LIVE

WORKDIR /matchingEngine

RUN npm install

ENTRYPOINT ["npm", "start"]
