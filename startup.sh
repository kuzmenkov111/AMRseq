#!/bin/bash


set -e

if [ -f /etc/configured ]; then
        chown -R shiny:shiny /srv/shiny-server
        chown -R shiny:shiny /var/lib/shiny-server/bookmarks
        echo 'already configured'
else
      #code that need to run only one time ....
      chown -R shiny:shiny /srv/shiny-server
      chown -R shiny:shiny /var/lib/shiny-server/bookmarks        
        #needed for fix problem with ubuntu and cron
        update-locale 
        date > /etc/configured
fi
