ARG STACK_VERSION=18
FROM heroku/heroku:$STACK_VERSION-build
ARG STACK_VERSION

ENV STACK=heroku-$STACK_VERSION
ENV DEBIAN_FRONTEND noninteractive
LABEL com.gliderlabs.herokuish/stack=$STACK

RUN apt-get update -qq \
    && apt-get install -qq -y daemontools \
    && cp /etc/ImageMagick-6/policy.xml /etc/ImageMagick-6/policy.xml.custom \
    && apt-get -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew \
    --allow-downgrades \
    --allow-remove-essential \
    --allow-change-held-packages \
    dist-upgrade \
    && mv /etc/ImageMagick-6/policy.xml.custom /etc/ImageMagick-6/policy.xml \
    && apt-get clean \
    && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* /var/tmp/*
RUN curl "https://github.com/gliderlabs/herokuish/releases/download/v0.5.32/herokuish_0.5.32_linux_x86_64.tgz" \
    --silent -L | tar -xzC /bin
RUN /bin/herokuish buildpack install \
    && ln -s /bin/herokuish /build \
    && ln -s /bin/herokuish /start \
    && ln -s /bin/herokuish /exec \
    && cd /tmp/buildpacks \
    && rm -rf \
    */.git \
    */.github \
    */.circleci \
    */changelogs \
    */spec \
    */support/build \
    */builds \
    */test \
    */tmp
COPY include/default_user.bash /tmp/default_user.bash
RUN bash /tmp/default_user.bash && rm -f /tmp/default_user.bash
