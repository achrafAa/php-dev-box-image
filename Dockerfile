FROM ubuntu:latest

# Build arguments for PHP version and optional extensions
ARG PHP_VERSION=8.4.4
ARG PHP_MAJOR_VERSION=8.4
ARG ENABLE_EXTENSIONS=""

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PHP_VERSION=${PHP_VERSION}
ENV PHP_MAJOR_VERSION=${PHP_MAJOR_VERSION}
ENV PATH="/opt/php/bin:${PATH}"
ENV PKG_CONFIG_PATH="/opt/php/lib/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig"

# Install system dependencies and build tools
RUN apt-get update && apt-get upgrade -y

# Install core build tools
RUN apt-get install -y \
    build-essential \
    autoconf \
    automake \
    libtool \
    bison \
    flex \
    re2c \
    pkg-config \
    ca-certificates \
    gnupg \
    lsb-release \
    curl \
    wget

# Install essential PHP dependencies
RUN apt-get install -y \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libonig-dev \
    libreadline-dev \
    libsqlite3-dev \
    zlib1g-dev

# Install development and debugging tools
RUN apt-get install -y \
    gdb \
    valgrind \
    strace \
    git \
    nano \
    vim \
    unzip \
    htop \
    tree \
    jq

# Install optional PHP extension dependencies (available if needed)
RUN apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libpq-dev \
    libicu-dev \
    libbz2-dev \
    libxslt1-dev \
    libgmp-dev \
    libldap2-dev \
    libsasl2-dev \
    libffi-dev \
    libargon2-dev \
    libsodium-dev \
    && rm -rf /var/lib/apt/lists/*

# Install potentially problematic packages separately
RUN apt-get update && apt-get install -y \
    libkrb5-dev \
    libtidy-dev \
    libsnmp-dev \
    libenchant-2-dev \
    && rm -rf /var/lib/apt/lists/* || true

# Try to install libc-client-dev separately (can be problematic)
RUN apt-get update && apt-get install -y libc-client-dev && rm -rf /var/lib/apt/lists/* || \
    echo "Warning: libc-client-dev not available, IMAP support will be limited"

# Install Zig compiler
RUN curl -L https://ziglang.org/download/0.14.0/zig-linux-x86_64-0.14.0.tar.xz | tar -xJ -C /opt/ \
    && ln -s /opt/zig-linux-x86_64-0.14.0/zig /usr/local/bin/zig

# Create directories
RUN mkdir -p /usr/src/php/src && mkdir -p /opt/php

# Download and extract PHP source code
RUN cd /usr/src/php/src && \
    wget -O php-${PHP_VERSION}.tar.gz "https://github.com/php/php-src/archive/refs/tags/php-${PHP_VERSION}.tar.gz" && \
    tar -xzf php-${PHP_VERSION}.tar.gz && \
    mv php-src-php-${PHP_VERSION} php-src && \
    rm php-${PHP_VERSION}.tar.gz

# Configure and compile PHP with debug symbols
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

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Create convenience scripts
RUN echo '#!/bin/bash\ncd /usr/src/php/src/php-src && php ext/ext_skel.php "$@"' > /usr/local/bin/ext_skel && \
    chmod +x /usr/local/bin/ext_skel

# Create a script to generate extension skeleton
RUN echo '#!/bin/bash\n\
set -e\n\
if [ $# -eq 0 ]; then\n\
    echo "Usage: create-extension <extension_name>"\n\
    echo "Creates a new PHP extension skeleton in the current directory"\n\
    exit 1\n\
fi\n\
\n\
EXTENSION_NAME="$1"\n\
echo "Creating PHP extension: $EXTENSION_NAME"\n\
\n\
# Use ext_skel to create the extension\n\
cd /usr/src/php/src/php-src\n\
php ext/ext_skel.php --ext="$EXTENSION_NAME" --dir="/workdir"\n\
\n\
echo "Extension $EXTENSION_NAME created successfully in /workdir/$EXTENSION_NAME"\n\
echo "To build the extension:"\n\
echo "  cd /workdir/$EXTENSION_NAME"\n\
echo "  phpize"\n\
echo "  ./configure"\n\
echo "  make"\n\
echo "  make test"\n\
' > /usr/local/bin/create-extension && \
    chmod +x /usr/local/bin/create-extension

# Create a script to build extensions
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
if [ ! -f "config.m4" ]; then\n\
    echo "Error: config.m4 not found. Are you in an extension directory?"\n\
    exit 1\n\
fi\n\
\n\
echo "Building PHP extension..."\n\
\n\
# Clean previous builds\n\
make clean 2>/dev/null || true\n\
\n\
# Generate configure script\n\
phpize\n\
\n\
# Configure with debug flags\n\
./configure --enable-debug CFLAGS="-g -O0"\n\
\n\
# Build\n\
make -j$(nproc)\n\
\n\
echo "Build completed successfully!"\n\
echo "To test: make test"\n\
echo "To install: make install"\n\
' > /usr/local/bin/build-extension && \
    chmod +x /usr/local/bin/build-extension

# Create workspace directory
WORKDIR /workdir

# Create helpful aliases and environment setup
RUN echo 'alias ll="ls -la"' >> /root/.bashrc && \
    echo 'alias la="ls -la"' >> /root/.bashrc && \
    echo 'alias php-debug="gdb php"' >> /root/.bashrc && \
    echo 'export PS1="\[\033[01;32m\]\u@php-dev:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> /root/.bashrc

# Create info script
RUN echo '#!/bin/bash\n\
echo "=== PHP Extension Development Environment ==="\n\
echo "PHP Version: $(php --version | head -n1)"\n\
echo "PHP Binary: $(which php)"\n\
echo "PHP Source: /usr/src/php/src/php-src/"\n\
echo "Zig Version: $(zig version)"\n\
echo ""\n\
echo "Available commands:"\n\
echo "  create-extension <name>  - Create new extension skeleton"\n\
echo "  build-extension          - Build extension in current directory"\n\
echo "  ext_skel                 - Direct access to ext_skel.php"\n\
echo "  phpize                   - Prepare extension for building"\n\
echo ""\n\
echo "Development tools:"\n\
echo "  php (debug build)        - PHP interpreter with debug symbols"\n\
echo "  gdb                      - GNU Debugger"\n\
echo "  valgrind                 - Memory debugging"\n\
echo "  zig                      - Zig compiler"\n\
echo "  git, nano, vim           - Development utilities"\n\
echo ""\n\
echo "Volume mount your extension code to /workdir"\n\
echo "Example: docker run -v \$(pwd):/workdir -it php-dev:8.4.4"\n\
' > /usr/local/bin/info && \
    chmod +x /usr/local/bin/info

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
LABEL maintainer="PHP Extension Development Environment"
LABEL description="Pre-built PHP development environment with debug symbols and development tools"
LABEL php.version="${PHP_VERSION}"
LABEL tools="php,gdb,valgrind,zig,git,nano,vim"

# Default command
CMD ["/bin/bash", "-c", "info && exec /bin/bash"] 