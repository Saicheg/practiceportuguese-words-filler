FROM ruby:3.2-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./

RUN bundle install

COPY . .

ENTRYPOINT ["ruby", "run.rb"] 
