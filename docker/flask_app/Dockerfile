FROM python:3.8.6-slim-buster
LABEL maintainer="vvoll@protonmail.com"
WORKDIR /app
COPY . /app
RUN pip install -r requirements.txt
ENV FLASK_ENV=production
