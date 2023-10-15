#!/bin/bash

# variable definition
response='/home/tetrex/Projects/bash-web-server/response'

#creating fifo named pipes
rm -f response && mkfifo response


# 1) Process the request
# 2) Route request to the correct handler
# 3) Build a response based on the request
# 4) Send the response to the named pipe (FIFO)
handleRequest() {
  while read line; do
    echo $line
    trline=`echo $line | tr -d '[\r\n]'`

    # condition check
    [-z "$trline"] && break
  
  done

  echo -e 'HTTP/1.1 200 OK\r\n\r\n\r\n<h1>PONGG</h1>' > response

}

echo 'Listening on 3000...'

cat response | nc -nvlN 3000 | handleRequest


