FROM alpine:3.21

RUN apk add --no-cache \
	build-base \
	dpkg-dev \
	dpkg \
	gnupg \
	libc-dev \
	linux-headers \
	ncurses-dev \
    openssl-dev

ENV OTP_VERSION 27.2
ENV OTP_SOURCE_SHA256="b66c2cc4fa2c87211b668e4486d4f3e5b1b6705698873ea3e6d9850801ac992d"
ENV ERLANG_INSTALL_PATH_PREFIX /opt/erlang

ARG BUILDKIT_SBOM_SCAN_STAGE=true

RUN set -eux; \
# /usr/local/src doesn't exist in Alpine by default
	mkdir -p /usr/local/src; \
	\
	OTP_SOURCE_URL="https://github.com/erlang/otp/releases/download/OTP-$OTP_VERSION/otp_src_$OTP_VERSION.tar.gz"; \
	OTP_PATH="/usr/local/src/otp-$OTP_VERSION"; \
	\
	mkdir -p "$OTP_PATH"; \
	wget --output-document "$OTP_PATH.tar.gz" "$OTP_SOURCE_URL"; \
	echo "$OTP_SOURCE_SHA256 *$OTP_PATH.tar.gz" | sha256sum -c -; \
	tar --extract --file "$OTP_PATH.tar.gz" --directory "$OTP_PATH" --strip-components 1; \
	\
	cd "$OTP_PATH"; \
	export ERL_TOP="$OTP_PATH"; \
	export CFLAGS='-g -O2'; \
	hostArch="$(dpkg-architecture --query DEB_HOST_GNU_TYPE)"; \
	buildArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	dpkgArch="$(dpkg --print-architecture)"; dpkgArch="${dpkgArch##*-}"; \
	jitFlag=; \
	case "$dpkgArch" in \
		amd64 | arm64) jitFlag='--enable-jit' ;; \
	esac; \
	./configure \
		--prefix="$ERLANG_INSTALL_PATH_PREFIX" \
		--host="$hostArch" \
		--build="$buildArch" \
		--disable-hipe \
		--disable-sctp \
		--disable-silent-rules \
		--enable-builtin-zlib \
		--enable-clock-gettime \
		--enable-hybrid-heap \
		--enable-kernel-poll \
		--enable-smp-support \
		--enable-threads \
		--with-microstate-accounting=extra \
		--without-common_test \
		--without-debugger \
		--without-dialyzer \
		--without-diameter \
		--without-edoc \
		--without-erl_docgen \
		--without-et \
		--without-eunit \
		--without-ftp \
		--without-hipe \
		--without-jinterface \
		--without-megaco \
		--without-observer \
		--without-odbc \
		--without-reltool \
		--without-ssh \
		--without-tftp \
		--without-wx \
        --enable-jit
