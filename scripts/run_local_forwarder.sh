pushd "$(dirname $0)/.." &>/dev/null
read -p "What day would you like to start search for receipts from? \
Use this format: mm/dd/yyyy HH:mm:ss: " date_str
if ! date_unix=$(date -d "$date_str" +%s)
then
  >&2 echo "ERROR: Unable to understand this date: $date_str"
  exit 1
fi

read -p "Enter your email address: " email_address
if test -z "$email_address"
then
  >&2 echo "ERROR: You must supply an email address."
  exit 1
fi

export CREDENTIALS_FILE_PATH=$PWD/credentials.json
export TOKEN_FILE_PATH=$PWD/tokens.yml
docker-compose run -e "FORWARDER_LAST_FINISHED_TIME_SECS=$date_unix" \
  -e "EMAIL_SENDER=$email_address" \
  -e "USE_AWS=false" \
  --rm forwarder
popd &>/dev/null
