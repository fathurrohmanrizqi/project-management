# -----------------------------
# Stage 1: Install Composer Deps
# -----------------------------
FROM composer:2 AS deps
WORKDIR /app
COPY composer.json composer.lock ./
# Install dependencies agar folder /vendor terbentuk
RUN composer install --no-dev --no-scripts --no-autoloader --ignore-platform-reqs

COPY . .
RUN composer dump-autoload --optimize

# -----------------------------
# Stage 2: Build Frontend (Node)
# -----------------------------
FROM node:20 AS frontend
WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

# Copy seluruh project
COPY . .

# [PENTING] Copy folder vendor dari Stage 1 agar Vite bisa membaca file Filament
COPY --from=deps /app/vendor ./vendor

# Sekarang build aman karena folder vendor sudah ada
RUN npm run build

# -----------------------------
# Stage 3: Laravel (PHP 8.3) - Final Image
# -----------------------------
FROM php:8.3-fpm AS app

# Install dependencies sistem
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libzip-dev \
    libicu-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    unzip \
    zip \
    git \
    curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_pgsql intl zip gd opcache

# Config Apache/PHP (Optional, sesuaikan kebutuhan production)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy project files
COPY . .

# Copy vendor dari Stage 1 (Deps)
COPY --from=deps /app/vendor ./vendor

# Copy hasil build frontend dari Stage 2 (Frontend)
COPY --from=frontend /app/public/build ./public/build

# Set permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Expose port
EXPOSE 8000

# Jalankan server
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]