#!/bin/bash

# Author: Brian Adams - github.com/autotune
# MIT Licence

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

echo "Script PID is $$"
{
PTS=$(ps ax|grep 'ssh rack@'|grep -v "grep"|wc -l)
TTY=$(tty|grep -o '[0-9]*')
TMP='/home/rack/tmp.txt'
EXCLUDES='/home/rack/excludes.txt'

# check for env variables
if [[ -z "$NAME" ]];
then 
	NAME="Rackspace"
else
	NAME="$NAME"
fi 

if [[ -z "$USERS" ]];
then
        USERS="1"
else
        USERS="$USERS"
fi


if [[ -z "$MINUTES" ]];
then
	MINUTES="15"
else
	MINUES="$MINUTES"
fi

CONVERTED=$(($MINUTES * 60))

# we need to exit after X minutes in case someone doesn't log out of console or other unknown error
while [ $SECONDS -lt $CONVERTED ]
do
# output to two files. If tmp is different from existing, it means a new rack user has signed on. Find process id and kick off
if [[ -e "$EXCLUDES" ]];
then
		rm -fr $TMP && touch $TMP
		for (( i=0; i<=$PTS + 2; i++ ))
        	do
                # output process id of each login
                PID=$(ps -fu rack|grep sshd|grep rack@pts/$i|grep -v grep)
		echo $PID|grep -v "grep"|grep -v '^$'|awk '{print $2}' >> $TMP 
	        echo $(cat $TMP|sort -nr > /home/rack/tmp2.txt && mv /home/rack/tmp2.txt $TMP)
		done
elif [[ ! -e "$EXCLUDES" ]];
	then
		for (( j=0; j<=$PTS + 2; j++ ))
                do
                # output process id of each login
                PID=$(ps -fu rack|grep sshd|grep rack@pts/$j|grep -v grep)
		echo $PID|grep -v "grep"|grep -v '^$'|awk '{print $2}' >> $EXCLUDES
		
 	done	
fi

# check if tmp file has new rack pids
if [[ $(diff $TMP $EXCLUDES) != "" ]];
then
	# spit out the number of rack users we want to kick
	NUM=$(expr $(cat $TMP|wc -l) - $(cat $EXCLUDES|wc -l))
	# if users greater than number of rack users logged in

	# todo: refactor this code block
	if (($USERS > $NUM));
	then
		echo "Number needs to be greater than $(expr $USERS - $NUM)"
	else
		echo $(expr $NUM - $USERS)
		for (( k=1; k<=$(expr $NUM - $USERS + 1); k++))
        	do
			echo "Hi there, this system is currently in use by $NAME. Try again in $(expr $CONVERTED - $SECONDS ) seconds" > /home/rack/test1.txt && write rack < /home/rack/test1.txt
			echo $(kill -9 $(awk "NR==$k" $TMP))
		done
	fi
fi

continue;
done
# suppress console output
} &> /dev/null
