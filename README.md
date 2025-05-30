# PHP Core & Extension Development Docker Image

A pre-built Docker image that provides a complete PHP development environment for both **PHP core development** and **PHP extension development** with debug symbols, development tools, and the Zig compiler. Eliminates the need for time-consuming PHP compilation by providing a ready-to-use development environment.

## 🚀 Quick Start

```bash
# Build the image
docker build -t php-dev-box .

# Run interactively
docker run -v $(pwd):/workdir -it --rm php-dev-box

# Using docker-compose
docker-compose -f docker.yml up -d
docker-compose -f docker.yml exec php-dev-box bash
```

## 🛠️ What's Included

### Core Development Environment
- **PHP** compiled from source with debug symbols (`--enable-debug`)
- **PHP source code** available at `/usr/src/php/src/php-src/`
- **ext_skel.php** ready for extension skeleton generation
- **phpize** for extension configuration
- **Full PHP build environment** for core development

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

### PHP Extensions (Enabled)
- Core extensions: mbstring, intl, bcmath, gd, zip, etc.
- Database: MySQLnd, PDO (MySQL, SQLite, PostgreSQL)
- Security: OpenSSL, Sodium, Argon2
- And many more...

## 📝 Available Commands

Once inside the container, you have access to these convenience commands:

```bash
# Create a new extension skeleton
create-extension <extension_name>

# Build extension in current directory
build-extension

# Direct access to ext_skel.php
ext_skel --ext=myext

# Prepare extension for building
phpize

# Show environment information
info

# Debug PHP with GDB
php-debug
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
create-extension myawesome
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
build-extension

# Run tests
make test

# Install extension
make install

# Load extension in PHP
php -dextension=myawesome.so -m | grep myawesome
```

#### 4. Debug Your Extension
```bash
# Debug with GDB
gdb php
(gdb) run -dextension=modules/myawesome.so your_test.php

# Memory debugging with Valgrind
valgrind --leak-check=full php -dextension=modules/myawesome.so your_test.php
```

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
PKG_CONFIG_PATH=/opt/php/lib/pkgconfig:$PKG_CONFIG_PATH
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

/usr/local/bin/             # Custom scripts
├── create-extension        # Extension skeleton generator
├── build-extension         # Extension builder
├── ext_skel               # Direct ext_skel access
└── info                   # Environment information
```

## 🔍 Debugging Tips

### Debugging PHP Core
```bash
# Start debugging session for PHP core
gdb /opt/php/bin/php
(gdb) set args -f your_script.php
(gdb) break zend_compile_file
(gdb) break zend_execute
(gdb) run

# Debug specific PHP components
(gdb) break php_request_startup
(gdb) break php_request_shutdown
```

### Debugging Extensions
```bash
# Start debugging session for extensions
gdb php
(gdb) set args -dextension=./modules/myext.so test.php
(gdb) break zif_myext_function
(gdb) run
```

### Memory Debugging
```bash
# Check for memory leaks in PHP core
valgrind --leak-check=full --show-leak-kinds=all php your_script.php

# Check for memory leaks in extensions
valgrind --leak-check=full --show-leak-kinds=all php -dextension=./modules/myext.so test.php

# Check for undefined behavior
valgrind --tool=memcheck php your_script.php
```

### Using Zig for Development
```bash
# Compile C code with Zig for additional safety checks
zig cc -g -O0 -shared -fPIC myext.c -o myext.so $(php-config --includes)

# Use Zig for PHP core development (experimental)
zig cc -g -O0 -c main/main.c $(php-config --includes)
```

## 🌟 Features

### ✅ Instant Setup
- No 10+ minute PHP compilation time
- Pre-built with all dependencies
- Ready-to-use development environment

### ✅ Debug-Ready
- PHP compiled with debug symbols
- GDB and Valgrind included
- Optimized for core and extension debugging

### ✅ Complete Development Environment
- Full PHP source code access
- All build tools and dependencies
- Support for both core and extension development

### ✅ Modern Tools
- Zig compiler for additional development options
- Git, nano, vim for development
- Comprehensive build toolchain

### ✅ Developer-Friendly
- Convenient wrapper scripts
- Informative help commands
- Volume mounting for code persistence

## 🎯 Use Cases

### PHP Core Development
- Working on Zend Engine improvements
- Developing new PHP language features
- Fixing PHP core bugs
- Performance optimizations
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