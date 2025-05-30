# Multi-stage build for faster compilation
FROM ubuntu:latest AS builder

# Build arguments for PHP version and optional extensions
ARG PHP_VERSION=8.4.4
ARG PHP_MAJOR_VERSION=8.4
ARG ENABLE_EXTENSIONS=""

# Set environment variables for build
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies in fewer layers
RUN apt-get update && apt-get install -y \
    build-essential autoconf automake libtool bison flex re2c pkg-config \
    libxml2-dev libssl-dev libcurl4-openssl-dev libonig-dev libreadline-dev \
    libsqlite3-dev zlib1g-dev curl wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Download PHP source and Zig in parallel
RUN mkdir -p /usr/src/php/src /opt && \
    # Download PHP source in background
    (cd /usr/src/php/src && \
     wget -O php-${PHP_VERSION}.tar.gz "https://github.com/php/php-src/archive/refs/tags/php-${PHP_VERSION}.tar.gz" && \
     tar -xzf php-${PHP_VERSION}.tar.gz && \
     mv php-src-php-${PHP_VERSION} php-src && \
     rm php-${PHP_VERSION}.tar.gz) & \
    # Download Zig in parallel
    (curl -L https://ziglang.org/download/0.14.0/zig-linux-x86_64-0.14.0.tar.xz | tar -xJ -C /opt/) & \
    wait

# Configure and compile PHP (optimized for speed)
WORKDIR /usr/src/php/src/php-src
RUN ./buildconf --force && \
    ./configure \
        --prefix=/opt/php \
        --enable-debug \
        --enable-cli \
        --enable-fpm \
        --enable-mbstring \
        --enable-opcache \
        --with-openssl \
        --with-curl \
        --with-zlib \
        --with-readline \
        --with-sqlite3 \
        --with-pdo-sqlite \
        ${ENABLE_EXTENSIONS} \
        CFLAGS="-g -O0" \
        CXXFLAGS="-g -O0" && \
    make -j$(nproc) && \
    make install

# Final stage - much smaller and faster
FROM ubuntu:latest

# Copy build arguments
ARG PHP_VERSION=8.4.4
ARG PHP_MAJOR_VERSION=8.4

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PHP_VERSION=${PHP_VERSION}
ENV PHP_MAJOR_VERSION=${PHP_MAJOR_VERSION}
ENV PATH="/opt/php/bin:${PATH}"
ENV PKG_CONFIG_PATH="/opt/php/lib/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig"

# Install only runtime dependencies and development tools (combined for speed)
RUN apt-get update && apt-get install -y \
    # PHP runtime dependencies
    libxml2 libssl3 libcurl4 libonig5 libreadline8 libsqlite3-0 zlib1g \
    # Essential development tools
    gdb valgrind strace git nano vim curl wget unzip htop tree jq \
    # Build tools for extensions
    build-essential autoconf automake libtool bison flex re2c pkg-config \
    # Optional extension libraries (lightweight)
    libxml2-dev libssl-dev libcurl4-openssl-dev libonig-dev libreadline-dev \
    libsqlite3-dev zlib1g-dev ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled PHP from builder stage
COPY --from=builder /opt/php /opt/php
COPY --from=builder /usr/src/php/src/php-src /usr/src/php/src/php-src
COPY --from=builder /opt/zig-linux-x86_64-0.14.0 /opt/zig-linux-x86_64-0.14.0

# Create Zig symlink and install Composer (parallel)
RUN ln -s /opt/zig-linux-x86_64-0.14.0/zig /usr/local/bin/zig && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy development Makefile
COPY Makefile.php-dev /usr/local/bin/Makefile.php-dev

# Create a global alias/shortcut script
RUN echo '#!/bin/bash\nmake -f /usr/local/bin/Makefile.php-dev "$@"' > /usr/local/bin/phpdev && \
    chmod +x /usr/local/bin/phpdev

# Create workspace directory
WORKDIR /workdir


# Set up PHP configuration for development
RUN mkdir -p /opt/php/etc && \
    echo 'error_reporting = E_ALL\n\
display_errors = On\n\
display_startup_errors = On\n\
log_errors = On\n\
error_log = /tmp/php_errors.log\n\
memory_limit = 512M\n\
max_execution_time = 0\n\
opcache.enable = 0\n\
' > /opt/php/etc/php.ini

# Add labels for the image
LABEL maintainer="Achraf AAMRI"
LABEL description="Pre-built PHP development environment with debug symbols and development tools"
LABEL php.version="${PHP_VERSION}"
LABEL tools="php,gdb,valgrind,zig,git,nano,vim"

# Default command
CMD ["/bin/bash", "-c", "phpdev info && exec /bin/bash"] 