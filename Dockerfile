# Build hugo site
FROM docker.io/floryn90/hugo:0.161.1-ext-ubuntu AS builder

ARG TRAINING_HUGO_ENV=default

COPY . /src

RUN hugo --environment ${TRAINING_HUGO_ENV} --minify

# build pdf
FROM docker.io/ubuntu:noble AS wkhtmltopdf
RUN apt-get update \
    && apt-get install -y curl \
    && curl -L https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb --output wkhtmltox_0.12.6.1-2.jammy_amd64.deb \
    && ls -la \
    && apt-get install -y /wkhtmltox_0.12.6.1-2.jammy_amd64.deb \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /wkhtmltox_0.12.6.1-2.jammy_amd64.deb

COPY --from=builder /src/public /

RUN wkhtmltopdf --enable-internal-links --enable-local-file-access \
    --margin-top 35mm --margin-bottom 22mm --margin-left 15mm --margin-right 10mm \
    --enable-internal-links --enable-local-file-access \
    --header-html /pdf/header/index.html --footer-html /pdf/footer/index.html \
    /pdf/index.html /pdf.pdf

# build static files
FROM docker.io/ubuntu:noble AS zipper
RUN apt-get update && apt-get install -y zip && rm -rf /var/lib/apt/lists/*
COPY ./static-content/backstage-data /backstage-data
RUN zip -r /backstage-data.zip /backstage-data

# build runtime container
FROM docker.io/nginxinc/nginx-unprivileged:1.30-alpine

LABEL maintainer="Puzzle ITC <https://www.puzzle.ch/>"
LABEL org.opencontainers.image.authors="Puzzle ITC <https://www.puzzle.ch/>"
LABEL org.opencontainers.image.title="puzzle.ch's Backstage Basics Training"
LABEL org.opencontainers.image.description="Container with puzzle.ch's Backstage Techlab content for https://backstage-techlab.puzzle.ch/"
LABEL org.opencontainers.image.source="https://github.com/puzzle/backstage-techlab/"
LABEL org.opencontainers.image.licenses="CC-BY-SA-4.0"

USER root
COPY nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /usr/share/nginx/html/static && \
    chown -R nginx /usr/share/nginx/html/static
USER 101

EXPOSE 8080

COPY --from=builder /src/public /usr/share/nginx/html
COPY --from=wkhtmltopdf /pdf.pdf /usr/share/nginx/html/pdf/pdf.pdf

COPY ./static-content/ /usr/share/nginx/html/static
COPY --from=zipper /backstage-data.zip /usr/share/nginx/html/static/backstage-data.zip
