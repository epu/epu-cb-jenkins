#
# Cookbook Name:: jenkins
# HWRP:: credentials_password
#
# Author:: Seth Chisamore <schisamo@getchef.com>
#
# Copyright 2013-2014, Chef Software, Inc.
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

require_relative 'credentials'
require_relative '_params_validate'

class Chef
  class Resource::JenkinsPrivateKeyCredentials < Resource::JenkinsCredentials
    require 'openssl'

    # Chef attributes
    provides :jenkins_private_key_credentials

    # Set the resource name
    self.resource_name = :jenkins_private_key_credentials

    # Actions
    actions :create, :delete
    default_action :create

    # Attributes
    attribute :private_key,
      kind_of: [String, OpenSSL::PKey::RSA, OpenSSL::PKey::DSA],
      required: true
    attribute :passphrase,
      kind_of: String

    #
    # Private key of the credentials . This should be the actual key
    # contents (as opposed to the path to a private key file) in OpenSSH
    # format.
    #
    # @param [String] arg
    # @return [String]
    #
    def to_pem(key=private_key)
      if key.is_a?(OpenSSL::PKey::RSA)
        Chef::Log.debug("private_key: is a OpenSSL::PKey::RSA (ruby openssl object)")
        key.to_pem
      elsif key.is_a?(OpenSSL::PKey::DSA)
        Chef::Log.debug("private_key: is a OpenSSL::PKey::DSA (ruby openssl object)")
        key.to_pem
      elsif key =~ /-----BEGIN RSA PRIVATE KEY-----/
        Chef::Log.debug("private_key: is text containing 'BEGIN RSA PRIVATE KEY' comment.")
        OpenSSL::PKey::RSA.new(key).to_pem
      elsif key =~ /-----BEGIN DSA PRIVATE KEY-----/
        Chef::Log.debug("private_key: is text containing 'BEGIN DSA PRIVATE KEY' comment.")
        OpenSSL::PKey::DSA.new(key).to_pem
      else
        Chef::Log.debug("private_key: falling back to instantiate a new OpenSSL::PKey::RSA (ruby openssl object)")
        OpenSSL::PKey::RSA.new(key).to_pem
      end
    end
  end
end

class Chef
  class Provider::JenkinsPrivateKeyCredentials < Provider::JenkinsCredentials
    def load_current_resource
      @current_resource ||= Resource::JenkinsPrivateKeyCredentials.new(new_resource.name)

      super

      if current_credentials
        @current_resource.private_key(current_credentials[:private_key])
      end

      @current_resource
    end

    protected

    #
    # @see Chef::Resource::JenkinsCredentials#credentials_groovy
    # @see https://github.com/jenkinsci/ssh-credentials-plugin/blob/master/src/main/java/com/cloudbees/jenkins/plugins/sshcredentials/impl/BasicSSHUserPrivateKey.java
    #
    def credentials_groovy
      <<-EOH.gsub(/ ^{8}/, '')
        import com.cloudbees.plugins.credentials.*
        import com.cloudbees.jenkins.plugins.sshcredentials.impl.*

        private_key = """#{new_resource.to_pem}
        """

        credentials = new BasicSSHUserPrivateKey(
          CredentialsScope.GLOBAL,
          #{convert_to_groovy(new_resource.id)},
          #{convert_to_groovy(new_resource.username)},
          new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource(private_key),
          #{convert_to_groovy(new_resource.passphrase)},
          #{convert_to_groovy(new_resource.description)}
        )
      EOH
    end

    #
    # @see Chef::Resource::JenkinsCredentials#attribute_to_property_map
    #
    def attribute_to_property_map
      {
        private_key: 'credentials.privateKey',
        passphrase: 'credentials.passphrase.plainText',
      }
    end

    #
    # @see Chef::Resource::JenkinsCredentials#current_credentials
    #
    def current_credentials
      super

      # Normalize the private key
      if @current_credentials && @current_credentials[:private_key]
        # Handle DSA and RSA keys.
        @current_credentials[:private_key] = @current_resource.to_pem(key=@current_credentials[:private_key])
      end

      @current_credentials
    end
  end
end

Chef::Platform.set(
  resource: :jenkins_private_key_credentials,
  provider: Chef::Provider::JenkinsPrivateKeyCredentials
)
