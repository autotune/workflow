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
PTS=$(ps ax|grep 'ssh rack@'|grep -v "grep"|wc -l)
# TTY=$(tty|grep -o '[0-9]*')
TMP="/var/tmp/tmp$$.txt"
TMP2="/var/tmp/tmp02$$.txt"
EXCLUDES="/var/tmp/excludes$$.txt"
#PID=$(ps -fu rack|grep sshd|grep rack@pts)
# NUM=$(expr $(cat $TMP|wc -l) - $(cat $EXCLUDES|wc -l))
USER="rack"

touch $TMP
touch $TMP2

# check for env variables
if [[ -z "$NAME" ]];
then 
	NAME="YOUR_NAME"
else
	NAME="$NAME"
fi 

if [[ -z "$USER" ]];
then
	USER="$USER"
else
	USER="rack"
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

# output to two files. If tmp is different from existing, it means a new rack user has signed on. Find process id and kick off
if [[ -e $EXCLUDES ]];
then
	echo "Deleting..."
	echo $(rm -fr $EXCLUDES)

fi

function updateExcludes(){
	# fun tidbit, bash doesn't just store vars but also only runs them one time on declaration, hence the value of a function
	PID=$(ps -fu $USER|grep sshd|grep $USER@pts)
        echo "$PID" > "$EXCLUDES"
        echo "$(cat $EXCLUDES|awk '{print $2}'|sort -nr|grep -e '^$' -v > $TMP2)"
        mv "$TMP2" "$EXCLUDES"

}

function updateTMP(){
	PID=$(ps -fu $USER|grep sshd|grep $USER@pts)
        echo "$PID" > "$TMP"
        echo "$(cat $TMP|awk '{print $2}'|sort -nr|grep -e '^$' -v > $TMP2)"
        mv "$TMP2" "$TMP"

}
# output to two files. If tmp is different from existing, it means a new rack user has signed on. Find process id and kick off
# since excludes is only meant to be ran once, it makes since to run it first
if [[ ! -e "$EXCLUDES" ]] ;
then 	
	echo "Excludes doesn't exist"
	touch $EXCLUDES
	PID=$(ps -fu $USER|grep sshd|grep $USER@pts)
	EXCLLINES=$(cat $EXCLUDES|wc -l)
	updateExcludes
	updateTMP
	echo "Excludes updated"
fi

if [[ "$USERS" > "$EXCLLINES"||"$USERS" == "$EXCLLINES" ]];
then
EXCLLINES=$(cat $EXCLUDES|wc -l)
	echo "We good"
	echo "There are $USERS rack users set to keep"
	echo "There are $(cat $EXCLUDES|wc -l) lines in excludes file"
	echo "There are $(cat $TMP|wc -l) users in the tmp file"
	echo "There are $(expr $EXCLLINES - $USERS) users set to kick"
	updateTMP

fi

KICK="$(expr $EXCLLINES - $USERS)"
if [[ $KICK < $USERS ]];
then
	EXCLLINES=$(cat $EXCLUDES|wc -l)
	for (( k=1; k<=$(expr $EXCLLINES - $USERS); k++ ))
        do
              	echo "Killing user: # $(cat $EXCLUDES|awk "NR==$k")"
		echo "Hi there, this system is currently in use by $NAME. Try again in $(expr $CONVERTED - $SECONDS ) seconds" > "/var/tmp/$USER.txt" && write $USER < /var/tmp/$USER.txt
		# if [[ $(kill -9 "$(cat $EXCLUDES|awk "NR==$k")") != "^[0-9]" ]];
		# then
		#	continue;
		# else
			kill -9 "$(awk "NR==$k" $EXCLUDES)"
	done
	updateExcludes
fi

{ # SUPPRESSING FIRE
# we need to exit after X minutes in case someone doesn't log out of console or other unknown error
while [ $SECONDS -lt $CONVERTED ]
do
PID=$(ps -fu $USER|grep sshd|grep $USER@pts)
EXCLLINES=$(cat $EXCLUDES|wc -l)
TMPLINES=$(cat $TMP|wc -l)

if [[ -e "$EXCLUDES" ]];
then
        rm -fr $TMP && touch $TMP
	echo "Updating tmp file..."
	updateTMP
        echo "There are $USERS rack users set to keep"
        echo "There are $(cat $EXCLUDES|wc -l) lines in excludes file"
        echo "There are $(cat $TMP|wc -l) users in the tmp file"
        echo "There are $(expr $EXCLLINES - $USERS) users set to kick"
fi

# check if tmp file has new rack pids
if [[ "$EXCLLINES" != "$TMPLINES" ]];
then
	TMPLINES=$(cat $TMP|wc -l)
	echo "New rack user detected"
        for (( l=1; l<=$(expr $TMPLINES - $USERS); l++ ))
        do
		echo "$(cat $TMP)"
                echo "Killing user: $(cat $TMP|awk "NR==$l")"
		echo "Hi there, this system is currently in use by $NAME. Try again in $(expr $CONVERTED - $SECONDS ) seconds" > "/var/tmp/$USER.txt" && write $USER < /var/tmp/$USER.txt
                kill -9 "$(awk "NR==$l" $TMP)"
        done
	updateTMP
fi

continue;
done
} &> /dev/null # finish output suppression
