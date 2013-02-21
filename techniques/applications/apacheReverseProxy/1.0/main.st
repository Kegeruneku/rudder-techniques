#####################################################################################
# Copyright 2011-2013 Normation SAS
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

#####################################################################################
# This Technique installs and configures Apache HTTPd to act as a reverse proxy
# server.. See metadata.xml for more details.
#####################################################################################

bundle agent rudder_reverse_proxy_apache
{
  vars:
    "rudder_reverse_proxy_apache_service_name"
      string => "Apache (as a reverse proxy)";

  methods:
    "any" usebundle => rudder_reverse_proxy_apache_installation("${rudder_reverse_proxy_apache_service_name}");
    "any" usebundle => rudder_reverse_proxy_apache_configuration("${rudder_reverse_proxy_apache_service_name}");
}