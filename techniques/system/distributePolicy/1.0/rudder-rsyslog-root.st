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

# Disable Repeated message reduction or reports may be lost
$RepeatedMsgReduction off

# Provides TCP syslog reception
$ModLoad imtcp
$InputTCPServerRun &SYSLOGPORT&

# Provide udp for snare and compatibility with older syslog
$ModLoad imudp
$UDPServerRun &SYSLOGPORT&

# Load postgres module
$ModLoad ompgsql

# for Snare client
$EscapeControlCharactersOnReceive off

&if(STORE_ALL_CENTRALIZED_LOGS_IN_FILE)&
# Log everything
*.*	/var/log/rudder/reports/all.log
&endif&

# Direct to DB
$ActionQueueType Direct
$ActionQueueSaveOnShutdown on

# The RudderReportsFormat template specifies how to store
# the report in the database.
# nodeId : the node id
# ruleId : the Rule Id
# directiveId : the directive id
# eventtype : the severity
# policy : the policy name

$template RudderReportsFormat,"insert into RudderSysEvents (executionDate, nodeId, ruleId, directiveId, serial, Component, KeyValue, executionTimeStamp, eventType, msg, Policy) values ('%timereported:::date-rfc3339%','%msg:R,ERE,1,DFLT:.*##(.*)@#.*--end%', '%msg:R,ERE,1,DFLT:.*@@.*@@.*@@(.*)@@.*@@.*@@.*@@.*@@[^#]*##.*--end%' , '%msg:R,ERE,1,ZERO:.*@@.*@@.*@@.*@@(.*)@@.*@@.*@@.*@@[^#]*##.*--end%', '%msg:R,ERE,1,DFLT:.*@@.*@@.*@@.*@@.*@@(.*)@@.*@@.*@@[^#]*##.*--end%', '%msg:R,ERE,1,DFLT:.*@@.*@@.*@@.*@@.*@@.*@@(.*)@@.*@@[^#]*##.*--end%', '%msg:R,ERE,1,DFLT:.*@@.*@@.*@@.*@@.*@@.*@@.*@@(.*)@@[^#]*##.*--end%', '%msg:R,ERE,1,DFLT:.*@@.*@@.*@@.*@@.*@@.*@@.*@@.*@@([^#]*)##.*--end%', '%msg:R,ERE,1,DFLT:.*@@.*@@(.*)@@.*@@.*@@.*@@.*@@.*@@[^#]*##.*--end%', '%msg:R,ERE,1,DFLT:.*@#(.*)--end%', '%msg:R,ERE,1,DFLT:.*@@(.*)@@.*@@.*--end%' )",stdsql

# Filtering by content
# Process :
# We first store the data in the database, then we drop it to prevent
# it from reaching local storage in .log files.
# The report format is @@Policy@@State@@RuleId@@DirectiveId@@VersionId@@Component@@Key@@ExecutionTimeStamp##NodeId@#HumanReadableMessage
#
# 1 - Send every matching report in the database...
:msg, ereregex, "R: @@[ a-zA-Z0-9_\-]+?@@[a-zA-Z0-9_\-]{1,64}?@@[a-zA-Z0-9\-]+@@[a-zA-Z0-9\-]+?@@[0-9]+?@@.*?@@.*?@@[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{1,2}:[0-9]{2}##[a-zA-Z0-9\-]+?@#.*"  :ompgsql:${install_rsyslogd.rudder_postgres_server},rudder,rudder,${p.psql_password[2]};RudderReportsFormat

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

