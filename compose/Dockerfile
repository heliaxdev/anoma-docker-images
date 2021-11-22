# Image with validator secrets
ARG ANOMA_IMAGE
FROM ${ANOMA_IMAGE}

RUN rm /docker-entrypoint.d/*
ARG CHAIN_ID
ARG NODE_ID
COPY ${CHAIN_ID}/setup/${NODE_ID}/.anoma/ /data

ENTRYPOINT []
CMD anoman ledger
