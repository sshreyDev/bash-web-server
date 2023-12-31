#!/bin/bash

# variable definition
response='/home/tetrex/Projects/bash-web-server/response'

#creating fifo named pipes for response
rm -f ./response && mkfifo response


#handler functions
function handle_GET_home() {
  RESPONSE=$(cat ./home.html | \
    sed "s/{{$COOKIE_NAME}}/{{$COOKIE_VALUE}}/")
}

function handle_GET_login() {
  RESPONSE=$(cat ./login.html)
}

function handle_POST_login() {
  RESPONSE=$(cat post-login.http | \
    sed "s/{{cookie_name}}/$INPUT_NAME/" | \
    sed "s/{{cookie_value}}/$INPUT_VALUE/")
}

function handle_POST_logout() {
  RESPONSE=$(cat post-logout.http | \
    sed "s/{{cookie_namee}}/$COOKIE_NAME/" | \
    sed "/{{cookie_value}}/$COOKIE_VALUE/")
}

function handle_not_found() {
  RESPONSE=$(cat ./404.html)
}


function requestHandler() {
  #Read request 
  while read line; do
    echo $line
    ## Removes the \r\n from the EOL
    trline=`echo $line | tr -d '[\r\n]'`

    # reaching eol breaks the loop
    [[ -z "$trline" ]] && break

    HEADLINE_REGEX='(.*?)\s(.*?)\sHTTP.*?'
    [[ "$trline" =~ $HEADLINE_REGEX ]] && 
      REQUEST=$(echo $trline | sed -E "s/$HEADLINE_REGEX/\1 \2/")

    CONTENT_LENGTH_REGEX='Content-Length:\s(.*?)'
    [[ "$trline" =~ $CONTENT_LENGTH_REGEX ]] && 
      CONTENT_LENGTH=$(echo $trline | sed -E "s/$CONTENT_LENGTH_REGEX/\1/")

    COOKIE_REGEX='Cookie:\s(.*?)=(.*?).*?'
    [[ "$trline" =~ $COOKIE_REGEX ]] && 
      read COOKIE_NAME COOKIE_VALUE <<< $(echo "$trline" | sed -E "s/$COOKIE_REGEX/\1 \2/")
  done

  #Reads body
  if [[ ! -z "$CONTENT_LENGTH" ]]; then
    BODY_REGEX='(.*?)=(.*?)'

    while read -n$CONTENT_LENGTH -t1 body; do
      echo $body

      INPUT_NAME=$(echo $body | sed -E "s/$BODY_REGEX/\1/")
      INPUT_VALUE=$(echo $body | sed -E "s/$BODY_REGEX/\2/")
    done
  fi
  
  # Routing
  case "$REQUEST" in 
    "GET /login")   handle_GET_login ;;
    "GET /")        handle_GET_home ;;
    "POST /login")  handle_POST_login ;;
    "POST /logout") handle_POST_logout ;;
    *)              handle_not_found ;;
  esac

  echo -e "$RESPONSE" > response
}

echo 'Listening on 3000...'

# Keeping the server running forever.
while true; do
  cat response | nc -nvlN 127.0.0.1 3000 | requestHandler
done




