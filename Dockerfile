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

# Copy seluruh project (termasuk config vite)
COPY . .

# Copy folder vendor dari Stage 1 agar Vite bisa membaca file Filament/Library lain
COPY --from=deps /app/vendor ./vendor

# Build assets
RUN npm run build

# -----------------------------
# Stage 3: Laravel (Apache) - Production Ready
# -----------------------------
FROM php:8.3-apache AS app

# 1. Install System Dependencies (Postgres, Zip, GD, dll)
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

# 2. Config Apache DocumentRoot ke folder /public (PENTING untuk Laravel)
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# 3. Aktifkan mod_rewrite (Wajib untuk routing Laravel)
RUN a2enmod rewrite

# 4. Copy Dependencies dari Stage sebelumnya
WORKDIR /var/www/html
COPY . .
COPY --from=deps /app/vendor ./vendor
COPY --from=frontend /app/public/build ./public/build

# 5. Permission (User default Apache adalah www-data)
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# 6. Expose Port (Apache default menggunakan port 80)
EXPOSE 80
