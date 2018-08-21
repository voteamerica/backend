FROM node:latest

RUN mkdir /nodeAppPostPg
ADD ./nodeAppPostPg /nodeAppPostPg

RUN mkdir /emailHandler
ADD ./emailHandler /emailHandler

RUN mkdir /smsHandler
ADD ./smsHandler /smsHandler

RUN mkdir /matchingEngine
ADD ./matchingEngine /matchingEngine


#ENTRYPOINT ["sh"]
