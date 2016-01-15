name             'epu-cb-jenkins'
maintainer       'Erik Purins'
maintainer_email 'erik@purins.com'
license          'Apache 2.0'
description      'Installs and configures Jenkins CI master & slaves'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.1.7'

recipe 'master', 'Installs a Jenkins master'

depends 'apt',   '~> 2.7'
depends 'gdebi', '~> 1.1'
depends 'runit', '~> 1.5'
depends 'yum',   '~> 3.0'
