#!/bin/bash

set -e

trap exit INT TERM

if [ -z "$DOMAINS" ]; then
  echo "DOMAINS environment variable is not set"
  exit 1;
fi

until nc -z nginx 80; do
  echo "Waiting for nginx to start..."
  sleep 5s & wait ${!}
done

echo "========================================"
echo " Certbot start at $(date)"
if [ "$CERTBOT_TEST_CERT" != "0" ]; then
  test_cert_arg="--test-cert"
  echo " >>> Launched by test mode <<<"
fi
echo "========================================"

domains_fixed=$(echo "$DOMAINS" | tr -d \")
domain_list=($domains_fixed)
emails_fixed=$(echo "$CERTBOT_EMAILS" | tr -d \")
emails_list=($emails_fixed)
for i in "${!domain_list[@]}"; do
  domain="${domain_list[i]}"

  mkdir -p "/var/www/letsencrypt"

  # Check domain already initialized by Certbot
  if [ -e "/etc/letsencrypt/live/$domain/cert.pem" ]; then
    echo "Let's Encrypt certificate for $domain already exists"
    echo "Renewal process starting..."

    certbot renew
    continue
  fi

  email="${emails_list[i]}"
  if [ -z "$email" ]; then
    email_arg="--register-unsafely-without-email"
    echo "Obtaining the certificate for $domain without email"
  else
    email_arg="--email $email"
    echo "Obtaining the certificate for $domain with email $email"
  fi

  # If domain directory exists, rename it.
  if [ -d "/etc/letsencrypt/live/$domain" ]; then
    rm -rf "/etc/letsencrypt/live/_$domain"
    mv "/etc/letsencrypt/live/$domain" "/etc/letsencrypt/live/_$domain"
  fi

  # Initialize domain
  certbot certonly \
    --webroot \
    -w "/var/www/letsencrypt" \
    -d "$domain" \
    $test_cert_arg \
    $email_arg \
    --deploy-hook "touch /etc/nginx/nginx.conf" \
    --rsa-key-size "${CERTBOT_RSA_KEY_SIZE:-4096}" \
    --agree-tos \
    --noninteractive \
    --verbose || true
done
