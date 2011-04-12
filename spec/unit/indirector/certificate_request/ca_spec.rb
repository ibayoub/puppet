#!/usr/bin/env ruby
#
#  Created by Luke Kanies on 2008-3-7.
#  Copyright (c) 2007. All rights reserved.

require 'spec_helper'

require 'puppet/ssl/host'
require 'puppet/sslcertificates'
require 'puppet/sslcertificates/ca'
require 'puppet/indirector/certificate_request/ca'

describe Puppet::SSL::CertificateRequest::Ca do
  include PuppetSpec::Files

  before :each do
    Puppet[:ssldir] = tmpdir('ssl')

    Puppet::SSL::Host.ca_location = :local
    Puppet[:localcacert] = Puppet[:cacert]
    Puppet::SSLCertificates::CA.new.mkrootcert

    @ca = Puppet::SSL::CertificateAuthority.new
  end

  after :all do
    Puppet::SSL::Host.ca_location = :none
  end

  it "should have documentation" do
    Puppet::SSL::CertificateRequest::Ca.doc.should be_instance_of(String)
  end

  it "should use the :csrdir as the collection directory" do
    Puppet.settings.expects(:value).with(:csrdir).returns "/request/dir"
    Puppet::SSL::CertificateRequest::Ca.collection_directory.should == "/request/dir"
  end

  it "should overwrite the previous certificate request if allow_duplicate_certs is true" do
    Puppet[:allow_duplicate_certs] = true
    host = Puppet::SSL::Host.new("foo")
    host.generate_certificate_request
    @ca.sign(host.name)

    Puppet::SSL::Host.indirection.find("foo").generate_certificate_request

    Puppet::SSL::Certificate.indirection.find("foo").name.should == "foo"
    Puppet::SSL::CertificateRequest.indirection.find("foo").name.should == "foo"
    Puppet::SSL::Host.indirection.find("foo").state.should == "requested"
  end

  it "should reject a new certificate request if allow_duplicate_certs is false" do
    Puppet[:allow_duplicate_certs] = false
    host = Puppet::SSL::Host.new("bar")
    host.generate_certificate_request
    @ca.sign(host.name)

    expect { Puppet::SSL::Host.indirection.find("bar").generate_certificate_request }.should raise_error(/ignoring certificate request/)

    Puppet::SSL::Certificate.indirection.find("bar").name.should == "bar"
    Puppet::SSL::CertificateRequest.indirection.find("bar").should be_nil
    Puppet::SSL::Host.indirection.find("bar").state.should == "signed"
  end
end
