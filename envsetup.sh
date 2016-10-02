#!/bin/bash
#Get Environment Config Settings for laravel

BUILD_ENV=$1

eval APP_ENV=\$app_env_$BUILD_ENV
eval APP_DEBUG=\$app_debug_$BUILD_ENV
eval APP_URL=\$app_url_$BUILD_ENV
eval CACHE_DRIVER=\$cache_driver_$BUILD_ENV
eval QUEUE_DRIVER=\$queue_driver_$BUILD_ENV

#Create .env file and generate a unique APP_KEY
cd ~/proxy-cms-demo/dist
cp .env.example .env

php artisan key:generate
sed -i "s,^APP_ENV=.*,APP_ENV=$APP_ENV," .env
sed -i "s,^APP_DEBUG=.*,APP_DEBUG=$APP_DEBUG," .env
sed -i "s,^APP_URL=.*,APP_URL=$APP_URL," .env
sed -i "s,^CACHE_DRIVER=.*,CACHE_DRIVER=$CACHE_DRIVER," .env
sed -i "s,^QUEUE_DRIVER=.*,QUEUE_DRIVER=$QUEUE_DRIVER," .env
cat .env
