FROM heroku/cedar:14
RUN curl "https://github.com/gliderlabs/herokuish/releases/download/v0.3.33/herokuish_0.3.33_linux_x86_64.tgz" \
		--silent -L | tar -xzC /bin
RUN /bin/herokuish buildpack install \
	&& ln -s /bin/herokuish /build \
	&& ln -s /bin/herokuish /start \
	&& ln -s /bin/herokuish /exec
COPY include/default_user.bash /tmp/default_user.bash
RUN bash /tmp/default_user.bash && rm -f /tmp/default_user.bash
