# Use the official Ruby image as a base image
FROM ruby:3.3.3-slim-bullseye

RUN apt-get update -qq && apt-get install -yq --no-install-recommends \
    build-essential \
    gnupg2 \
    less \
    libssl-dev \
    bash \
    git \
    telnet \
    wget \
    nodejs \
    iproute2 \
    curl
    

RUN apt-get update -qq && apt-get install -y \
  libpq-dev

# openssl 3 required for puma to run
RUN wget https://www.openssl.org/source/openssl-3.0.10.tar.gz \
  && tar -xvf openssl-3.0.10.tar.gz \
  && cd openssl-3.0.10 \
  && ./config \
  && make \
  && make install

# Set the working directory
WORKDIR /app

# Copy the Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

RUN mkdir vpn
COPY ./vpn/ibis-openvpn.ovpn ./vpn/

# Install gems
RUN bundle install

# Copy the rest of the application code
COPY . ./

# Copy database from our home directory
# COPY .nsl/editor-database.yml /root/.nsl/editor-database.yml

RUN chmod 600 .pgpass

# Precompile assets (optional, if you have assets to precompile)
# RUN bundle exec rake assets:precompile

# Expose port 3000 to the outside world
EXPOSE 3000

# Start the Rails server
CMD ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec rails server -b 0.0.0.0 -p 3000"]