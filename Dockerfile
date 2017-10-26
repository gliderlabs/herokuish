FROM heroku/heroku:16
RUN apt-get update -qq && apt-get install -yy -q daemontools ruby-dev
RUN curl "https://github.com/gliderlabs/herokuish/releases/download/v0.3.32/herokuish_0.3.32_linux_x86_64.tgz" \
		--silent -L | tar -xzC /bin
RUN /bin/herokuish buildpack install \
	&& ln -s /bin/herokuish /build \
	&& ln -s /bin/herokuish /start \
	&& ln -s /bin/herokuish /exec
COPY include/default_user.bash /tmp/default_user.bash
RUN bash /tmp/default_user.bash && rm -f /tmp/default_user.bash
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
