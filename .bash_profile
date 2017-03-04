if [ -f ~/.bashrc ]; then . ~/.bashrc; fi

# http://unix.stackexchange.com/questions/18212/bash-history-ignoredups-and-erasedups-setting-conflict-with-common-history
# http://stackoverflow.com/questions/19454837/bash-histsize-vs-histfilesize
# number of lines or commands that are stored in memory in a history list while your bash session is ongoing.
export HISTSIZE=2000
# number of lines or commands that (a) are allowed in the history file at startup time of a session,
# and (b) are stored in the history file at the end of your bash session for use in future sessions.
export HISTFILESIZE=10000
# https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html
export HISTCONTROL=ignoreboth
# enable the writing of history on the fly, rather than on logout by editing your ~/.bashrc and adding:
# http://superuser.com/questions/649884/clear-terminal-output-of-last-command-only/649891#649891
shopt -s histappend
export PROMPT_COMMAND='history -a'

SSH_ENV="$HOME/.ssh/environment"

# import all id_rsa_* keys
function add_keys {
	find "$HOME/.ssh/" -not -name "*.pub" -name "id_rsa_*" | xargs ssh-add
}

# start the ssh-agent
function start_agent {
	echo -n "Initializing new SSH agent... "
	# spawn ssh-agent
	ssh-agent | sed 's/^echo/#echo/' > "$SSH_ENV"
	echo "succeeded"
	chmod 600 "$SSH_ENV"
	. "$SSH_ENV" > /dev/null
	add_keys
}

# test for identities
function test_identities {
	# test whether standard identities have been added to the agent already
	ssh-add -l | grep "The agent has no identities" > /dev/null
	if [ $? -eq 0 ]; then
		add_keys
		# $SSH_AUTH_SOCK broken so we start a new proper agent
		if [ $? -eq 2 ];then
			start_agent
		fi
	fi
}

# check for running ssh-agent with proper $SSH_AGENT_PID
if [ -n "$SSH_AGENT_PID" ]; then
	ps -f -u $USERNAME | grep "$SSH_AGENT_PID" | grep ssh-agent > /dev/null
	if [ $? -eq 0 ]; then
		test_identities
	fi
	# if $SSH_AGENT_PID is not properly set, we might be able to load one from
	# $SSH_ENV
else
	if [ -f "$SSH_ENV" ]; then
		. "$SSH_ENV" > /dev/null
	fi
	ps -f -u $USERNAME | grep "$SSH_AGENT_PID" | grep ssh-agent > /dev/null
	if [ $? -eq 0 ]; then
		test_identities
	else
		start_agent
	fi
fi
