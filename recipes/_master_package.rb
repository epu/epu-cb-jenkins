#
# Cookbook Name:: jenkins
# Recipe:: _master_package
#
# Author: Guilhem Lettron <guilhem.lettron@youscribe.com>
# Author: Seth Vargo <sethvargo@gmail.com>
#
# Copyright 2013, Youscribe
# Copyright 2014, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

case node['platform_family']
when 'debian'
  include_recipe 'apt::default'

  # See also http://pkg.jenkins-ci.org/debian-stable
  # -epu
  apt_repository 'jenkins' do
    uri          'http://pkg.jenkins-ci.org/debian'
    distribution 'binary/'
    key          'https://jenkins-ci.org/debian/jenkins-ci.org.key'
  end

  if node['jenkins']['master']['version'] != nil
    apt_preference 'jenkins' do
      pin          "version #{node['jenkins']['master']['version']}"
      pin_priority '1001'
      notifies :run, 'execute[apt-get-update]', :immediately
    end
    # would be nice to use /var/cache/apt/archives by default.
    # But, is this overridable? Welp. Throw it in the cache anyways.
    jenkins_deb_name = "jenkins_#{node['jenkins']['master']['version']}_all.deb"
    remote_file "/var/cache/apt/archives/#{jenkins_deb_name}" do
      source "http://pkg.jenkins-ci.org/debian/binary/#{jenkins_deb_name}"
      # The jenkins Packages definition doesn't include release information for its historical debs, only the latest.
      # That means, there is no secure way to update to a specific release because its checksums are lost to time.
    end
  end
  
  
  package 'jenkins' do
    version node['jenkins']['master']['version']
  end

  template '/etc/default/jenkins' do
    source   'jenkins-config-debian.erb'
    mode     '0644'
    notifies :restart, 'service[jenkins]', :immediately
  end
when 'rhel'
  include_recipe 'yum::default'

  yum_repository 'jenkins-ci' do
    baseurl 'http://pkg.jenkins-ci.org/redhat'
    gpgkey  'https://jenkins-ci.org/redhat/jenkins-ci.org.key'
  end

  package 'jenkins' do
    version node['jenkins']['master']['version']
  end

  template '/etc/sysconfig/jenkins' do
    source   'jenkins-config-rhel.erb'
    mode     '0644'
    notifies :restart, 'service[jenkins]', :immediately
  end
end

service 'jenkins' do
  supports status: true, restart: true, reload: true
  action  [:enable, :start]
end
