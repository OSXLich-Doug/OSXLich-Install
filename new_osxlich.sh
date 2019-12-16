#!/usr/bin/env bash

#  osxlich.sh
#
#
#  Created by doug on 7/30/16
#  Core Updates after launch of OS X Catalina
#  version 2.1
# 4/15/17 - updated for Sierra
# 4/15/18 - updated for High Sierra
# 4/16/18 - updated Ruby logic to install 2.2.5 on High Sierra (2.3) machines
# 6/10/18 - updated cairo location to reverse Homebrew decision to remove x11
# 12/15/19 - updated to use archive of required brew formulas to properly install post-Catalina

# Welcome to the automagic Mac OS X Lich install script
# I am prepared to turn your Mac system
# into an awesome Siumtronics gaming machine via Tillmen Magic.
# Script built and maintained by Doug (doug@play.net)

# Logging, yay

today_Date=$(date +"%F")
user_Name=$(whoami)
LOG="$user_Name-$today_Date-osxlich.txt"

exec > >( tee >( sed -l 's/\[[0-9]*m//g' >> ~/Desktop/"$LOG" ) )
exec 2>&1


# Let's set up a few constants here, shall we?

bold="\033[1m"
normal="\033[0m"

###########################################################################
##
##      Proc Defs
##
###########################################################################

# Time the install process

start_Timer () {

    SCRIPT_START=$(date)
    START_TIME=$SECONDS
    user_echo ""
    user_echo ""
    user_echo "${bold}\t   Welcome to Mac OS X and Lich Installer${normal}"
    user_echo "\t     Run at $SCRIPT_START"
    user_echo ""
    user_echo ""
}

end_Timer () {
    SCRIPT_END=$(date)
    hack_Timer 'Script'
    user_echo "\t  Ended at $SCRIPT_END"
}

hack_Timer () {
    local fmt="$1"

    ELAPSED_TIME=$(($SECONDS - $START_TIME))
    HOURS=$(($ELAPSED_TIME/60/60))
    MINUTES=$(($ELAPSED_TIME/60%60))
    SECS=$(($ELAPSED_TIME%60))

    if [[ "$SECONDS" ]]; then
        if [[ "$MINUTES" > "0" ]] && [[ "$HOURS" > "0" ]]; then
            user_echo "\n${bold}$fmt finished in $HOURS hr, $MINUTES min, and $SECS sec from script start${normal}"
        elif [[ "$MINUTES" > "0" ]] && [[ "$HOURS" == "0" ]]; then
            user_echo "\n  ${bold}$fmt finished in $MINUTES min, and $SECS sec from script start${normal}"
        else
            user_echo "\n\t${bold}$fmt finished in $SECS sec from script start${normal}"
        fi
    fi

}

finish_Msg () {
	if $XQUARTZREQ; then
		user_echo "\n${bold}As a reminder, you will be logged out of your"
		user_echo "Mac GUI session, and be required to log back in.${normal}"
		sleep 15s
		osascript -e 'tell application "loginwindow" to  «event aevtrlgo»'
	fi
}

end_Msg () {
    local fmt="$1"
	if $XQUARTZREQ; then
		finish_Msg
	else	
		user_echo "${bold}\tYOU MUST EXIT THIS WINDOW AND START A FRESH TERMINAL SESSION.${normal}"
		user_echo ""
		user_echo "${bold}\t If you do not, you will experience errors, but nothing is broken. ${normal}"
		user_echo ""
		user_echo "${bold}\t\t ENJOY! ${normal}"
	fi
}

# Get your echo on

user_echo() {
    local fmt="$1"; shift
    printf "$fmt\n" "$@"
}

# Proc to append to bash_profile

append_to_bash() {
    local text="$1" bashloc
    local skip_new_line="${2:-0}"

    if [ -w "$HOME/.bash_profile.local" ]; then
        bashloc="$HOME/.bash_profile.local"
    else
        bashloc="$HOME/.bash_profile"
    fi

    if ! grep -Fqs "$text" "$bashloc"; then
        if [ "$skip_new_line" -eq 1 ]; then
            printf "%s\n" "$text" >> "$bashloc"
        else
            printf "\n%s\n" "$text" >> "$bashloc"
        fi
    fi
}


# Color me a picture worthy of words
# display a message in red with an x by it
function echo_fail {
    # echo first argument in red
    printf " \e[31m✘"
    # reset colours back to normal
    echo "\033[0m"
}

# display a message in green with a tick by it
function echo_pass {
    # echo first argument in green
    printf " \e[32m✔"
    # reset colours back to normal
    echo "\033[0m"
}


# Return version of ruby

ruby_ver() {
    ruby -v
}

# Return OS version

os_ver() {
    sw_vers -productVersion
}

# Return CLT status

CLT_ver() {
    pkgutil --pkg-info=com.apple.pkg.CLTools_Executables
}

# Return xQuartz status

XQ_ver() {
    pkgutil --info org.macosforge.xquartz.pkg
}

###########################################################################
##
##      End Proc Defs
##
###########################################################################

start_Timer

# Welcome message

user_echo "\n${bold}This will install software to run Lich on your Mac."
user_echo "If you use this machine to develop software, especially in ruby"
user_echo "I would strongly encourage you to stop this script and review"
user_echo "it carefully.  It will attempt to install Ruby managers and gems."
user_echo "You may also be required to log back into OS X and rerun this"
user_echo "script one time. Please consider this.${normal}"

user_echo ""

# Prompt to continue
read -p "  Continue? (y/n) " ans
if [[ $ans != "y" ]]; then
    user_echo "\nQuitting...\n"
    exit
fi


# This determines ths version of Mac OSX
# Will only function on Mac OSX
# Continue extending to other implementations via uname

valid_os="$(os_ver)"

if [[ "$valid_os" =~ "10.9" ]]; then
    user_echo "OS X Mavericks detected.  OS Supported. $(echo_pass)"
    user_echo ""
elif [[ "$vaild_os" =~ "10.10" ]]; then
    user_echo "OS X Yosemite detected.  OS Supported. $(echo_pass)"
    user_echo ""
elif [[ "$valid_os" =~ "10.11" ]]; then
    user_echo "OS X El Capitan detected.  OS Supported. $(echo_pass)"
    user_echo ""
elif [[ "$valid_os" =~ "10.12" ]]; then
    user_echo "OS X Sierra detected.  OS Supported.  $(echo_pass)"
    user_echo ""
elif [[ "$valid_os" =~ "10.13" ]]; then
    user_echo "OS X High Sierra detected.  OS Supported.  $(echo_pass)"
    user_echo ""
elif [[ "$valid_os" =~ "10.14" ]]; then
    user_echo "OS X Mojave detected.  OS Supported.  $(echo_pass)"
    user_echo ""
elif [[ "$valid_os" =~ "10.15" ]]; then
    user_echo "OS X Catalina detected.  OS Supported.  $(echo_pass)"
    user_echo ""
else
    user_echo "${bold}Your Mac OS is $valid_os, and is not supported.  $(echo_fail)"
    user_echo "There may be hope, but you'll have to work manually to install everything."
    user_echo "You can email doug@play.net to see if assistance is available.${normal}"
    user_echo ""
    exit
fi

# This determines if brew has been installed.
# Interesting thing about brew is it will install the CLT automatically
# if needed, and it has xQuartz in a delivery mode that doesn't require
# exiting Terminal and restarting it.  Inorite?

# So our order will be
# Check for brew - if found, fall back to xQuartz and beyond.
# If not found (brew) - install brew (which gets CLT)
# then install everything elsee
# This means we can drop the CLT check, because either it
# exists with brew, or it gets installed with brew.
# We'll test everything on exit, though.
# First, though - let's check for rvm

# This check is to determine if either
# rvm is presently installed on the system
# if not present, rbenv will be installed
# If it is present, bail out!

if command -v rvm >/dev/null; then
    user_echo "It appears that this system already has"
    user_echo "the rvm ruby manager installed.  Because"
    user_echo "this usually means that the sytsem is"
    user_echo "actively being used for development in"
    user_echo "Ruby, and because rvm and the manager"
    user_echo "that this script installs (rbenv) do NOT"
    user_echo "play well together, I am going to stop"
    user_echo "and exit here.  Seek further guidance"
    user_echo "from doug@play.net"
    user_echo ""
    sleep 5s
    exit
else
    user_echo "Ruby manager rvm is not detected.  $(echo_pass)"
    user_echo ""
fi

# Now brew (installs CLT if not present)

if ! command -v brew >/dev/null; then
    user_echo "Homebrew is not installed.  $(echo_fail)"
    user_echo "Installing Homebrew. You will be asked for your password."
    user_echo ""
    curl -fsS 'https://raw.githubusercontent.com/Homebrew/install/master/install' | ruby
else
    user_echo "Homebrew detected. $(echo_pass)"
    user_echo ""
fi

hack_Timer 'Homebrew checkpoint'

# Now xQuartz
valid_XQ="$(XQ_ver)"
XQUARTZREQ=FALSE

if [[ "$valid_XQ" =~ "version" ]]; then
    user_echo "Your system already has xQuartz installed.  $(echo_pass)";
    user_echo ""
else
	XQUARTZREQ=TRUE
    brew tap Caskroom/cask
    brew install Caskroom/cask/xquartz
fi

hack_Timer 'xQuartz checkpoint'


# This check is to determine your existing active
# Ruby version and revision.  If greater than 2.0
# no action need be taken, but we should determine
# how that newer version of Ruby is managed

installed_ver="$(ruby_ver)"

RUBYREQ=FALSE

if [[ "$installed_ver" =~ "2.0.0" ]] ; then
    user_echo "Ruby version 2.0.0 detected.  Will update. $(echo_fail)"
    user_echo ""
    RUBYREQ=TRUE
elif [[ "$installed_ver" =~ "2.1" ]] || [[ "$installed_ver" =~ "2.2" ]] ; then
    user_echo "Ruby version 2.1 or 2.2 detected.  Will update. $(echo_fail)"
    user_echo ""
elif [[ "$installed_ver" =~  "2.3" ]] || [[ "$installed_ver" =~ "2.4" ]]; then
    user_echo "Ruby version 2.3 or 2.4 detected.  Installing supported Ruby version (2.6.5). $(echo_pass)"
    user_echo ""
	RUBYREQ=TRUE
elif [[ "$installed_ver" =~ "2.5" ]]; then
	user_echo "Ruby version 2.5 detected.  Installing supporting Ruby version (2.6.5). $(echo_pass)"
	user_echo ""
	RUBYREQ=TRUE
elif [[ "$installed_ver" =~ "2.6" ]]; then
	user_echo "Ruby version 2.6 detected.  Installing non-sudo Ruby version (2.6.5). $(echo_pass)"
	user_echo ""
	RUBYREQ=TRUE
else
	user_echo "For some reason, I've failed to detect a Ruby version I understand.  $(echo_fail)"
	user_echo "May need help.  Exiting. . ."
	exit
fi


# Getting down to brass tacks here.  At this point, we
# know the envrionment well enough to start our installations

user_echo "Updating Homebrew for latest formulas."
user_echo ""
brew update
if ! brew list | grep -Fq rbenv; then
    user_echo "Installing rbenv"
    user_echo ""
    brew install rbenv
    rbenv init
    append_to_bash 'eval "$(rbenv init - )"' '1'
else
    user_echo "You have rbenv already installed. $(echo_pass)"
fi

hack_Timer 'rbenv checkpoint'

# Time to go after Ruby updates

if $RUBYREQ; then
    user_echo "Changing system Ruby to Ruby version 2.6.5."
    user_echo ""
    rbenv install 2.6.5
    user_echo "Setting Ruby version 2.6.5 as the global Ruby."
    user_echo ""
    source ./.bash_profile
    sleep 5s
    rbenv global 2.6.5
    ruby -v
    rbenv rehash
    gem update --system
fi

hack_Timer 'Ruby 2.6.5 checkpoint'

# Grabbing the archived formulas which will build the dylibs needed to support Lich

curl -OL https://github.com/OSXLich-Doug/OSXLich-Install/raw/master/OldSkoolBrew.zip
unzip OldSkoolBrew.zip
cp ./OldSkoolBrew/* /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core/Formula/

hack_Timer 'Archive files in place.  Light it up!'



if ! brew list | grep -Fq cairo; then
    user_echo "Installing Cairo and dependencies"
    HOMEBREW_NO_AUTO_UPDATE=1 brew install cairo
    brew pin cairo
else
    user_echo "You have Cairo already installed. $(echo_pass)"
fi

hack_Timer 'Cairo checkpoint'

if ! brew list | grep -Fq gtk+; then
    user_echo "Installing gtk+ and dependencies including pango"
    user_echo ""
    HOMEBREW_NO_AUTO_UPDATE=1 brew install pango gtk+
    brew pin gtk+
    brew pin pango
else
    user_echo "You have gkt+ libraries already installed. $(echo_pass)"
fi

hack_Timer 'gtk+ checkpoint'

# Check to see if a gem is installed

if ! gem spec sqlite3 > /dev/null 2>&1; then
    user_echo "Gem sqlite3 is not installed.  $(echo_fail)"
    user_echo "Installing sqlite3 and related dependencies."
    user_echo ""
    gem install sqlite3 --no-document
    rbenv rehash
else
    user_echo "Gem sqlite3 already installed. $(echo_pass)"
fi

hack_Timer 'sqlite3 checkpoint'

if ! gem spec gtk2 > /dev/null 2>&1; then
    user_echo "Gem gtk2 is not installed.  $(echo_fail)"
    user_echo "Installing gtk2 and related dependencies."
    user_echo ""
    gem install gtk2 --no-document
    rbenv rehash
else
    user_echo "Gem gtk2 already installed.  $(echo_pass)"
fi

hack_Timer 'gtk2 checkpoint'

# Nearly done.  Check to see if this script's default locations
# for these files shows the files to exist.  If not, then
# grab Avalon and Lich and put them in their locations

if [ -d ~/lich ]; then
    user_echo "Lich is installed in the best location. $(echo_pass)"
else
    cd
    curl -OL http://lichproject.org/download/lich-4.6.52.zip
    unzip lich-4.6.52.zip
    rm lich-4.6.52.zip
	sudo chown -R $(whoami):staff ./lich
fi

if [ -d $HOME/Desktop/Avalon4.3.3.app ] || [ -d $HOME/Desktop/Avalon4.3.5.app ]; then
    user_echo "Avalon is installed on the Desktop.  $(echo_pass)"
else
    cd
    curl -OL http://www.play.net/software/Avalon4.3.5.zip
    open -a "Archive Utility" Avalon4.3.5.zip && sleep 5s
    mv Avalon4.3.5.app $HOME/Desktop/
    rm Avalon4.3.5.zip
	sudo chown -R $(whoami):staff $HOME/Desktop/Avalon4.3.5
fi

user_echo "Process complete."
user_echo ""

# Print the time elapsed

end_Timer

user_echo ""
user_echo ""
end_Msg
user_echo""
user_echo""

sleep 15s

exit
