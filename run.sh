#! /usr/bin/env ash
set -e # exit on error

# Variables
if [ -z "$SMTP_LOGIN" -o -z "$SMTP_PASSWORD" ] ; then
	echo "SMTP_LOGIN and SMTP_PASSWORD _must_ be defined"
	exit 1
fi

readonly LDAP_SSL_KEY="/etc/ssl/private/ssl-cert-snakeoil.key"
readonly LDAP_SSL_CERT="/etc/ssl/certs/ssl-cert-snakeoil.pem"

export SMTP_LOGIN SMTP_PASSWORD
export EXT_RELAY_HOST=${EXT_RELAY_HOST:-"smtp.ipage.com"}
export EXT_RELAY_PORT=${EXT_RELAY_PORT:-"587"}
export RELAY_HOST_NAME=${RELAY_HOST_NAME:-"zentek.com.mx"}
export ACCEPTED_NETWORKS=${ACCEPTED_NETWORKS:-"192.168.0.0/16 172.16.0.0/12 10.0.0.0/8"}
export USE_TLS=${USE_TLS:-"no"}
export TLS_VERIFY=${TLS_VERIFY:-"may"}

echo $RELAY_HOST_NAME > /etc/mailname

make_snakeoil_certificate() {
    echo "Make snakeoil certificate for ${RELAY_HOST_NAME}..."
    openssl req -subj "/CN=${RELAY_HOST_NAME}" \
                -new \
                -newkey rsa:2048 \
                -days 365 \
                -nodes \
                -x509 \
                -keyout ${LDAP_SSL_KEY} \
                -out ${LDAP_SSL_CERT}

    chmod 600 ${LDAP_SSL_KEY}
}

if [ ! -e /bootstrap/docker_bootstrapped ]; then
  # Snakeoil certificate
  make_snakeoil_certificate

  # Templates
  j2 /bootstrap/main.cf > /etc/postfix/main.cf
  j2 /bootstrap/sasl_passwd > /etc/postfix/sasl_passwd
  postmap /etc/postfix/sasl_passwd
  postalias /etc/aliases

  # Launch
  rm -f /var/spool/postfix/pid/*.pid
  exec /usr/bin/supervisord -n -c /etc/supervisord.conf

  touch /bootstrap/docker_bootstrapped
else
  # Launch
  rm -f /var/spool/postfix/pid/*.pid
  exec /usr/bin/supervisord -n -c /etc/supervisord.conf
fi
# End of file
# vim: set ts=2 sw=2 noet:
