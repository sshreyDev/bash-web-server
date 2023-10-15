#!/bin/bash

# variable definition
response='/home/tetrex/Projects/bash-web-server/response'

#creating fifo named pipes
rm -f response && mkfifo response


# 1) Process the request
# 2) Route request to the correct handler
# 3) Build a response based on the request
# 4) Send the response to the named pipe (FIFO)
requestHandler() {
  while read line; do
    echo $line
    trline=`echo $line | tr -d '[\r\n]'`

    # condition check
    [-z "$trline"] && break

    HEADLINE_REGEX='(.*?)\s(.*?)\sHTTP.*?'

    [[ "$trline" =~ $HEADLINE_REGEX ]] && 
      REQUEST=$(echo $trline | sed -E "s/$HEADLINE_REGEX/\1 \2/")
  
  done

  case "$REQUEST" in 
    "GET / ") RESPONSE="HTTP/1.1 200 OK\r\nContent-type: text/html\r\n\r\n<h1>PONG</h1>" ;;
           *) RESPONSE="HTTP/1.1 404 NotFound\r\n\r\n\r\nNot Found"
    esac

  echo -e $RESPONSE > response

}

echo 'Listening on 3000...'

cat response | nc -nvlN 3000 | handleRequest


