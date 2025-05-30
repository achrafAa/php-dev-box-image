# PHP Core & Extension Development Docker Image

A pre-built Docker image that provides a complete PHP development environment for both **PHP core development** and **PHP extension development** with debug symbols, development tools, and the Zig compiler. Eliminates the need for time-consuming PHP compilation by providing a ready-to-use development environment.

## 🚀 Quick Start

```bash
# Build the image with minimal extensions (default)
docker build -t php-dev-box .

# Build with additional extensions
docker build --build-arg ENABLE_EXTENSIONS="--enable-gd --enable-intl --with-pdo-mysql --enable-zip" -t php-dev-box .

# Build a specific PHP version with extensions
docker build \
  --build-arg PHP_VERSION=8.3.15 \
  --build-arg PHP_MAJOR_VERSION=8.3 \
  --build-arg ENABLE_EXTENSIONS="--enable-bcmath --enable-gd --with-pdo-mysql" \
  -t php-dev-box:8.3 .

# Run interactively
docker run -v $(pwd):/workdir -it --rm php-dev-box

# Using docker-compose
docker-compose -f docker.yml up -d
docker-compose -f docker.yml exec php-dev-box bash
```

## 🔧 Available Extensions

### Included by Default
- **mbstring** - Multibyte string support
- **opcache** - Zend OPcache for performance
- **openssl** - OpenSSL support
- **curl** - cURL support
- **zlib** - Compression support
- **readline** - Command line editing
- **sqlite3** - SQLite support
- **pdo-sqlite** - SQLite PDO driver

### Optional Extensions (via build args)
You can enable additional extensions by passing them to `ENABLE_EXTENSIONS`:

```bash
# Database extensions
--enable-mysqlnd --with-pdo-mysql --with-pdo-pgsql

# Graphics and media
--enable-gd --enable-exif

# Internationalization
--enable-intl --enable-gettext

# Compression and archives
--enable-zip --with-bz2

# Math and crypto
--enable-bcmath --with-gmp --with-sodium --with-password-argon2

# Web services
--enable-soap --enable-ftp --enable-sockets

# Development utilities
--with-xsl --enable-calendar --with-ffi

# System integration
--with-ldap --with-ldap-sasl --enable-sysvmsg --enable-sysvsem --enable-sysvshm
```

### Example Builds for Different Use Cases

```bash
# Web development (MySQL, GD, internationalization)
docker build --build-arg ENABLE_EXTENSIONS="--enable-mysqlnd --with-pdo-mysql --enable-gd --enable-intl --enable-zip" -t php-dev-box:web .

# API development (JSON, cURL, crypto)
docker build --build-arg ENABLE_EXTENSIONS="--with-sodium --with-password-argon2 --enable-ftp --enable-sockets" -t php-dev-box:api .

# Full-featured (most common extensions)
docker build --build-arg ENABLE_EXTENSIONS="--enable-mysqlnd --with-pdo-mysql --with-pdo-pgsql --enable-gd --enable-intl --enable-zip --enable-bcmath --with-bz2 --enable-soap --enable-sockets" -t php-dev-box:full .
```

## 🛠️ What's Included

### Core Development Environment
- **PHP** compiled from source with debug symbols (`--enable-debug`)
- **PHP source code** available at `/usr/src/php/src/php-src/`
- **ext_skel.php** ready for extension skeleton generation
- **phpize** for extension configuration
- **Full PHP build environment** for core development

### PHP Extensions (Default Minimal Set)
- **Core**: CLI, FPM, OPcache
- **String**: mbstring
- **Network**: OpenSSL, cURL
- **Database**: SQLite3, PDO-SQLite
- **Compression**: zlib
- **Interactive**: readline
- **Additional extensions** available via build arguments

### Development Tools
- **GDB** - GNU Debugger for debugging PHP core and extensions
- **Valgrind** - Memory debugging and profiling
- **Strace** - System call tracer
- **Git** - Version control
- **Nano/Vim** - Text editors
- **Zig** - Modern systems programming language compiler

### Build Tools
- **GCC/G++** - C/C++ compilers
- **Autoconf/Automake** - Build system tools
- **Bison/Flex** - Parser generators
- **re2c** - Lexer generator
- **Make** - Build automation
- **pkg-config** - Library configuration

### System Libraries (Available for Extensions)
All major development libraries are pre-installed for optional extensions:
- Database: MySQL, PostgreSQL clients
- Graphics: PNG, JPEG, FreeType, GD
- Compression: BZ2, ZIP
- Internationalization: ICU
- Security: Sodium, Argon2
- And many more...

## 📝 Available Commands

### Primary Command: `phpdev`
The main command that provides access to all development tasks:

```bash
# Show help and available targets
phpdev help

# Show environment information
phpdev info

# Create a new extension skeleton
phpdev create EXT=myext

# Build extension in current directory
phpdev build

# Run extension tests
phpdev test

# Install built extension
phpdev install

# Clean build artifacts
phpdev clean

# Start GDB debugging session
phpdev debug

# Basic code linting
phpdev lint

# Memory debugging with Valgrind
phpdev valgrind
```

### Makefile-Based Workflow
You can also use the Makefile directly for more control:

```bash
# Use the development Makefile directly
make -f /usr/local/bin/Makefile.php-dev help
make -f /usr/local/bin/Makefile.php-dev create EXT=myext
make -f /usr/local/bin/Makefile.php-dev build
```

## 🏗️ Development Workflows

### PHP Core Development

#### 1. Working with PHP Source
```bash
# Enter the container
docker run -v $(pwd):/workdir -it --rm php-dev-box

# Navigate to PHP source
cd /usr/src/php/src/php-src

# Make changes to PHP core
nano Zend/zend_execute.c
# or
nano ext/standard/string.c
```

#### 2. Build and Test PHP Core
```bash
# Clean previous builds
make clean

# Reconfigure if needed
./buildconf --force
./configure --prefix=/opt/php --enable-debug CFLAGS="-g -O0"

# Build PHP
make -j$(nproc)

# Run tests
make test

# Install your custom PHP build
make install
```

#### 3. Debug PHP Core
```bash
# Debug PHP core with GDB
phpdev debug
# or manually:
gdb /opt/php/bin/php
(gdb) set args your_test_script.php
(gdb) break zend_execute
(gdb) run

# Memory debugging with Valgrind
valgrind --leak-check=full /opt/php/bin/php your_test_script.php
```

### PHP Extension Development

#### 1. Create Extension Skeleton
```bash
# Enter the container
docker run -v $(pwd):/workdir -it --rm php-dev-box

# Create new extension
phpdev create EXT=myawesome
cd myawesome
```

#### 2. Develop Your Extension
```bash
# Edit your extension code
nano myawesome.c
nano php_myawesome.h

# Modify config.m4 if needed
nano config.m4
```

#### 3. Build and Test Extension
```bash
# Build the extension
phpdev build

# Run tests
phpdev test

# Install extension
phpdev install

# Load extension in PHP
php -dextension=myawesome.so -m | grep myawesome
```

#### 4. Debug Your Extension
```bash
# Debug with GDB
phpdev debug

# Or manually
gdb php
(gdb) run -dextension=modules/myawesome.so your_test.php

# Memory debugging with Valgrind
phpdev valgrind
# or manually:
valgrind --leak-check=full php -dextension=modules/myawesome.so your_test.php
```

## 🚀 Build Optimizations

This image uses **multi-stage builds** for optimal performance:

### ✅ **Fast Build Process**
- **Parallel downloads**: PHP source and Zig compiler download simultaneously
- **Multi-stage build**: Compilation happens in builder stage, final image is optimized
- **Layer caching**: Efficient Docker layer strategy for faster rebuilds
- **Minimal final image**: Only runtime dependencies and development tools

### ✅ **Smart Extension Support**
- **Default minimal set**: Core extensions only (mbstring, opcache, openssl, curl, etc.)
- **Build-time customization**: Add extensions via `ENABLE_EXTENSIONS` build arg
- **All libraries available**: Full development libraries pre-installed for any extension

## 🔧 Configuration

### Custom PHP Configuration
The image includes a development-optimized `php.ini`:
```ini
error_reporting = E_ALL
display_errors = On
display_startup_errors = On
log_errors = On
memory_limit = 512M
max_execution_time = 0
opcache.enable = 0
```

### Environment Variables
```bash
PHP_VERSION=8.4.4           # PHP version
PATH=/opt/php/bin:$PATH     # PHP binaries in PATH
PKG_CONFIG_PATH=/opt/php/lib/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig
```

## 📁 Directory Structure

```
/opt/php/                   # PHP installation directory
├── bin/                    # PHP binaries (php, phpize, php-config)
├── lib/                    # PHP libraries
├── include/                # PHP headers
└── etc/                    # PHP configuration

/usr/src/php/src/php-src/   # PHP source code
├── ext/                    # Core extensions
├── Zend/                   # Zend engine
├── main/                   # PHP main components
├── sapi/                   # Server APIs
└── TSRM/                   # Thread safe resource manager

/workdir/                   # Mounted workspace (your code)

/usr/local/bin/             # Development tools
├── phpdev                  # Main development command
├── Makefile.php-dev        # Development Makefile
└── zig                    # Zig compiler
```

## 🌟 Features

### ✅ **Optimized Build Process**
- Multi-stage Docker build for speed and efficiency
- Parallel downloads for faster initial setup
- Smart layer caching for quick rebuilds
- Minimal runtime image size

### ✅ **Professional Development Environment**
- Makefile-based workflow with proper dependency management
- Both simple commands (`phpdev`) and granular control
- Comprehensive error checking and guidance
- Industry-standard development practices

### ✅ **Instant Setup**
- No 10+ minute PHP compilation time (pre-built)
- Ready-to-use development environment
- Flexible extension configuration

### ✅ **Debug-Ready**
- PHP compiled with debug symbols
- GDB and Valgrind included and integrated
- Optimized for both core and extension debugging

### ✅ **Complete Development Environment**
- Full PHP source code access
- All build tools and dependencies
- Support for both core and extension development
- Modern tools (Zig compiler, comprehensive toolchain)

### ✅ **Developer-Friendly**
- Intuitive command structure (`phpdev help`)
- Built-in help and guidance
- Backwards compatibility with traditional commands
- Volume mounting for code persistence

## 🎯 Use Cases

### PHP Core Development
- Working on Zend Engine improvements
- Developing new PHP language features
- Fixing PHP core bugs and optimizations
- Adding new SAPIs

### PHP Extension Development
- Creating custom PHP extensions
- Porting extensions to new PHP versions
- Debugging extension issues
- Performance testing extensions

### Research & Learning
- Understanding PHP internals
- Learning C programming with PHP
- Experimenting with language features
- Educational purposes

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Projects

- [PHP Source](https://github.com/php/php-src)

---

**Happy PHP Core & Extension Development! 🚀**