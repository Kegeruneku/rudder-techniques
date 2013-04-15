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

##########################################################################
# Installs requested packages by OS                                      #
#                                                                        #
# - RPM_PACKAGE_REDLIST --> The OS dependant packages to install         #
#                                                                        #
# - RPM_PACKAGE_REDACTION -->  The action to be made on these packages   #
#                                                                        #
# - RPM_PACKAGE_VERSION -->  The optionnal package version               #
#                                                                        #
##########################################################################

bundle agent check_rpm_package_installation {

  vars:
      "package_number" int => readstringarrayidx("rpm_data","${sys.workdir}/inputs/rpmPackageInstallation/3.0/rpmPackageInstallationData", "#[^\n]*",":",9000,1600000);

      "index_rpmpkg" slist => getindices("rpm_data");

  classes:

      "$(index_rpmpkg)_package_version_defined" not => strcmp("$(rpm_data[$(index_rpmpkg)][2])", "default");

	processes:

		SuSE_10::

			"/usr/lib/zmd/zmd.exe"
				restart_class => "zmd_restart";

	commands:

		zmd_restart::

			"/etc/init.d/novell-zmd"
				args => "restart",
				classes => kept_if_else("zmd_kept", "zmd_restarted", "could_not_restart_zmd"),
				comment => "Restart the ZMD daemon";

  packages:

    redhat|SuSE::
      "${rpm_data[${index_rpmpkg}][0]}"
        package_policy  => "${rpm_data[${index_rpmpkg}][1]}",
        package_method  => generic_nobulk("30"),
        classes => class_trigger_rpm_retcodes("rpm_package_installed_${index_rpmpkg}", "rpm_package_install_failed_${index_rpmpkg}", "rpm_package_install_kept_${index_rpmpkg}"),
        ifvarclass => "!${index_rpmpkg}_package_version_defined",
        comment => "Handling ${rpm_data[${index_rpmpkg}][0]} using yum_nobulk, policy : ${rpm_data[${index_rpmpkg}][1]}";

      "${rpm_data[${index_rpmpkg}][0]}"
        package_policy   => "${rpm_data[${index_rpmpkg}][1]}",
        package_method   => generic_nobulk("30"),
        package_select   => "${rpm_data[${index_rpmpkg}][3]}",
        package_version  => "${rpm_data[${index_rpmpkg}][2]}",
        classes => class_trigger_rpm_retcodes("rpm_package_installed_${index_rpmpkg}", "rpm_package_install_failed_${index_rpmpkg}", "rpm_package_install_kept_${index_rpmpkg}"),
        ifvarclass => "${index_rpmpkg}_package_version_defined",
        comment => "Handling ${rpm_data[${index_rpmpkg}][0]} using yum_nobulk, policy : ${rpm_data[${index_rpmpkg}][1]}";

  reports:

    redhat|SuSE::
      "@@packageInstallation@@result_repaired@@${rpm_data[${index_rpmpkg}][5]}@@RHEL/CentOS/SuSE packages@@${rpm_data[${index_rpmpkg}][0]}@@${g.execRun}##${g.uuid}@#Performed repair action for RPM package ${rpm_data[${index_rpmpkg}][0]} to comply with policy: ${rpm_data[${index_rpmpkg}][1]}"
        ifvarclass => canonify("rpm_package_installed_${index_rpmpkg}");

      "@@packageInstallation@@result_error@@${rpm_data[${index_rpmpkg}][5]}@@RHEL/CentOS/SuSE packages@@${rpm_data[${index_rpmpkg}][0]}@@${g.execRun}##${g.uuid}@#Error taking action for RPM package ${rpm_data[${index_rpmpkg}][0]} with policy: ${rpm_data[${index_rpmpkg}][1]}"
        ifvarclass => canonify("rpm_package_install_failed_${index_rpmpkg}");

      "@@packageInstallation@@result_success@@${rpm_data[${index_rpmpkg}][5]}@@RHEL/CentOS/SuSE packages@@${rpm_data[${index_rpmpkg}][0]}@@${g.execRun}##${g.uuid}@#No action required for RPM package ${rpm_data[${index_rpmpkg}][0]} with policy: ${rpm_data[${index_rpmpkg}][1]}"
        ifvarclass => canonify("rpm_package_install_kept_${index_rpmpkg}");

			# ZMD Process presence related reports
    !SuSE_10::
      "@@packageInstallation@@result_success@@${rpm_data[${index_rpmpkg}][5]}@@ZMD process@@None@@${g.execRun}##${g.uuid}@#ZMD process presence verification not necessary. Skipping ...";


    SuSE_10.!zmd_restart::
      "@@packageInstallation@@result_success@@${rpm_data[${index_rpmpkg}][5]}@@ZMD process@@None@@${g.execRun}##${g.uuid}@#The ZMD process is present. Skipping ...";

    SuSE_10.zmd_restarted::
      "@@packageInstallation@@result_repaired@@${rpm_data[${index_rpmpkg}][5]}@@ZMD process@@None@@${g.execRun}##${g.uuid}@#The ZMD daemon was successfully restarted";

    SuSE_10.could_not_restart_zmd::
      "@@packageInstallation@@result_error@@${rpm_data[${index_rpmpkg}][5]}@@ZMD process@@None@@${g.execRun}##${g.uuid}@#The ZMD daemon failed to restart";

}

body package_method generic_nobulk(rpm_pkg_timeout) {

redhat::
	package_changes => "individual";

	package_list_command => "/usr/bin/yum list installed";
	package_patch_list_command => "/usr/bin/yum check-update";
	package_list_name_regex    => "([^.]+).*";
	package_list_version_regex => "[^\s]\s+([^\s]+).*";
	package_list_arch_regex    => "[^.]+\.([^\s]+).*";
	package_installed_regex => ".*installed.*";
	package_name_convention => "$(name).$(arch)";
	package_list_update_ifelapsed => "$(rpm_pkg_timeout)";
	package_patch_installed_regex => "";
	package_patch_name_regex    => "([^.]+).*";
	package_patch_version_regex => "[^\s]\s+([^\s]+).*";
	package_patch_arch_regex    => "[^.]+\.([^\s]+).*";
	package_add_command => "/usr/bin/yum -y install";
	package_delete_command => "/bin/rpm -e";
	package_verify_command => "/bin/rpm -V";

SuSE_11::
	package_changes => "individual";

	package_list_command => "/bin/rpm -qa --queryformat \"i | repos | %{name} | %{version}-%{release} | %{arch}\n\"";
	package_list_update_ifelapsed => "$(rpm_pkg_timeout)";
	package_installed_regex => "i.*";
	package_list_name_regex => "[^|]+\|[^|]+\|\s+([^\s]+).*";
	package_list_version_regex => "[^|]+\|[^|]+\|[^|]+\|\s+([^\s]+).*";
	package_list_arch_regex => "[^|]+\|[^|]+\|[^|]+\|[^|]+\|\s+([^\s]+).*";
	package_name_convention => "$(name)";
	package_add_command => "/usr/bin/zypper --non-interactive install";
	package_delete_command => "/usr/bin/zypper --non-interactive remove --force-resolution";
	package_update_command => "/usr/bin/zypper --non-interactive update";
	package_verify_command => "/usr/bin/zypper --non-interactive verify$";

SuSE_10::
	package_changes => "individual";

	package_list_command => "/bin/rpm -qa --queryformat \"i | repos | %{name} | %{version}-%{release} | %{arch}\n\"";
	package_patch_list_command => "/usr/bin/rug patches";
	package_list_update_ifelapsed => "$(rpm_pkg_timeout)";
	package_installed_regex => "i.*";
	package_list_name_regex    => "[^|]+\|[^|]+\|\s+([^\s]+).*";
	package_list_version_regex => "[^|]+\|[^|]+\|[^|]+\|\s+([^\s]+).*";
	package_list_arch_regex    => "[^|]+\|[^|]+\|[^|]+\|[^|]+\|\s+([^\s]+).*";

	package_patch_installed_regex => ".*Installed.*|.*Not Applicable.*";
	package_patch_name_regex    => "[^|]+\|\s+([^\s]+).*";
	package_patch_version_regex => "[^|]+\|[^|]+\|\s+([^\s]+).*";

	package_name_convention => "$(name)";
	package_add_command => "/usr/bin/rug install -y";
	package_delete_command => "/usr/bin/rug remove -y";
	package_update_command => "/usr/bin/rug update -y";

	#Unsure about the behavior of this command ...
	#package_patch_command => "/usr/bin/rug patch-info";
	package_verify_command => "/usr/bin/rug verify -y$"; # $ means no args
}

body classes class_trigger_rpm_retcodes(if,else,kept)
{
	promise_kept => { "$(kept)" };
	promise_repaired => { "$(if)" };
	repair_failed => { "$(else)" };
	repair_denied    => { "$(else)" };
	repair_timeout   => { "$(else)" };

	# yum and rpm return 0 for almost anything so no difference between kept and repaired here
	kept_returncodes => { "0" };
	failed_returncodes => { "1" };
}
