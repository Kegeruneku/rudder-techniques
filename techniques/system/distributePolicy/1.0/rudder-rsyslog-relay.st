#####################################################################################
# Copyright 2011 Normation SAS
#####################################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, Version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#####################################################################################

# Rsyslog Rudder configuration

# Provides TCP syslog reception
$ModLoad imtcp
$InputTCPServerRun &SYSLOGPORT&

# Provide udp for snare and compatibility with older syslog
$ModLoad imudp
$UDPServerRun &SYSLOGPORT&

# for Snare client
$EscapeControlCharactersOnReceive off

&if(STORE_ALL_CENTRALIZED_LOGS_IN_FILE)&
# Log everything
*.*	/var/log/rudder/reports/all.log
&endif&


# Direct to DB
$ActionQueueType Direct
$ActionQueueSaveOnShutdown on

# Filtering by content
# Process :
# We first forward the data to the root server, then we drop it to prevent
# it from reaching local storage in .log files.
# The report format is @@Policy@@State@@RuleId@@DirectiveId@@VersionId@@Component@@Key@@ExecutionTimeStamp##NodeId@#HumanReadableMessage
#

# 1 - Send every matching report to the root server
:msg, ereregex, "R: @@[ a-zA-Z0-9_\-]+?@@[a-zA-Z0-9_\-]{1,64}?@@[a-zA-Z0-9\-]+@@[a-zA-Z0-9\-]+?@@[0-9]+?@@.*?@@.*?@@[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{1,2}:[0-9]{2}##[a-zA-Z0-9\-]+?@#.*" @@${server_info.cfserved}:&SYSLOGPORT&

# 2 - Drop the remaining rudder logs to prevent local storage cluttering

## Syslog messages from "rudder"
:programname, contains, "rudder" ~

## Syslog messages from "rudder" forwarded from AIX
:msg, ereregex, "from .*: rudder" ~

# Access Control list, localhost + all known agents 
$AllowedSender UDP, 127.0.0.0/8
$AllowedSender TCP, 127.0.0.0/8

&if(SKIPIDENTIFY)&

&AUTHORIZED_NETWORKS:{net|
$AllowedSender UDP, &net&
$AllowedSender TCP, &net&
}&

&else&

&MANAGED_NODES_IP : {ip |
$AllowedSender UDP, &ip&
$AllowedSender TCP, &ip&
} &

&endif&

