#!/bin/bash
####################################################################
# Created by Martin Tyrefors Branden (martin@tyrefors.com)	   #
####################################################################

# Suggestion for crontab:
# 00 00 * * * /bin/bash path/to/your/script.sh

# Set a user that is allowed to do LDAP searches.
LDAP_USER=""
LDAP_PASSWORD=""
LDAP_DOMAIN="dc=example,dc=com"
LDAP_SERVER="ipa.example.com"

USERS=`ldapsearch -D "uid=$LDAP_USER,cn=users,cn=accounts,$LDAP_DOMAIN" -w '$LDAP_PASSWORD' -b "cn=accounts,$LDAP_DOMAIN" -h $LDAP_SERVER | grep "User private group for" | awk '{print $6}'`

for USER in $USERS; do
        LAST_SUCCESSFUL_AUTH=`ldapsearch -D "uid=$LDAP_USER,cn=users,cn=accounts,$LDAP_DOMAIN" -w '$LDAP_PASSWORD' -b "uid=$USER,cn=users,cn=accounts,$LDAP_DOMAIN" -h $LDAP_SERVER | grep krbLastSuccessfulAuth | awk '{print $2}' | cut -c1-8`
        INACTIVE_LIMIT="30"
        LOCKOUT_LIMIT="90"
	    LIMIT_DATE="$(date "+%Y%m%d" -d "$INACTIVE_LIMIT days ago")"
        LOCKOUT_DATE="$(date "+%Y%m%d" -d "$LOCKOUT_LIMIT days ago")"
        if [ "$LAST_SUCCESSFUL_AUTH" != "" ]; then
                if [ "$LOCKOUT_DATE" -gt "$LAST_SUCCESSFUL_AUTH" ]; then
                        echo "$USER has been inactive for at least $LOCKOUT_LIMIT days."
                        LOCKOUT_USER="$LOCKOUT_USER $USER"
                elif [ "$LIMIT_DATE" -gt "$LAST_SUCCESSFUL_AUTH" ]; then
                        echo "User has been inactive for more than 30 days."
                        echo "Disabling user..."
                        DISABLE_EXEC=$(ipa user-disable $USER)
                else
                        echo "$USER is active, moving on..."
                fi
        else
                echo $USER "has never logged on"
        fi
done

if [ "$LOCKOUT_USER" != "" ]; then
        SUBJECT="Users inactive for at least $LOCKOUT_LIMIT in FreeIPA"
        EMAIL_ADDRESS="admin@example.com"
        for LUSER in $LOCKOUT_USER; do
                FULLNAME=`getent passwd $LUSER | cut -d ':' -f 5`
                echo "$LUSER - $FULLNAME" >> /tmp/ipamail.txt
        done
        send_email=`/bin/mail -s "$SUBJECT" "$EMAIL_ADDRESS" < /tmp/ipamail.txt`
        rm -rf /tmp/ipamail.txt
fi

