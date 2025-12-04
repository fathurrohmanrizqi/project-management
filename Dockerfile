# -----------------------------
# Stage 1: Build Frontend (Node)
# -----------------------------
FROM node:20 AS frontend

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY . .
RUN npm run build


# -----------------------------
# Stage 2: Laravel (PHP 8.3)
# -----------------------------
FROM php:8.3-fpm AS app

# Install dependencies
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libzip-dev \
    libicu-dev \
    unzip \
    zip \
    git \
    && docker-php-ext-install pdo pdo_pgsql intl zip

# Install composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy Laravel project
COPY . .

# Copy built assets from Node stage
COPY --from=frontend /app/public/build ./public/build

# Install PHP deps
RUN composer install --no-dev --optimize-autoloader

# Laravel optimize
RUN php artisan key:generate --force || true
RUN php artisan config:cache
RUN php artisan route:cache

EXPOSE 8000

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
