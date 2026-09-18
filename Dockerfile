# NOTE: This is primarily for TeamCity use atm.
#
# Use the official Ruby image as a base image
FROM ruby:3.4.8-bookworm

RUN apt-get update -qq && apt-get install -yq --no-install-recommends \
  build-essential \
  bash \
  wget \
  curl \
  ed

RUN apt-get update -qq && apt-get install -y \
  libpq-dev

# Copy the Gemfile and Gemfile.lock
COPY ./Gemfile ./Gemfile.lock ./

# Make Bundler 2.7 behave like Bundler 4 (deprecations become errors, checksums verified)
# ahead of the real upgrade. path.system keeps gems in the system gem dir; in
# simulation mode Bundler 2.7 would otherwise install them into ./.bundle, which the
# dev bind mount over /app hides.
ENV BUNDLE_SIMULATE_VERSION=4 \
    BUNDLE_PATH__SYSTEM=true

# Install the Bundler version pinned in Gemfile.lock (BUNDLED WITH), then the gems
RUN gem install bundler -v "$(tail -1 Gemfile.lock | tr -d ' ')" --no-document
RUN bundle install

WORKDIR /ruby-editor

# Copy the rest of the application code
COPY . ./
Run cp -r .nsl/ /root/

CMD ["/bin/bash", "-c", "echo 'Container started!' && echo 'Running post-start commands...' && RAILS_ENV=production rake build_prod && cd .. && pwd && ls -l && tar cfz ruby-editor.tgz ruby-editor && mv /ruby-editor.tgz /output/"]
