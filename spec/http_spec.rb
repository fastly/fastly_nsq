# frozen_string_literal: true

require "spec_helper"
require "fastly_nsq/http"

RSpec.describe FastlyNsq::Http, :webmock do
  let(:base_url) { "http://example.com" }
  describe "get" do
    it "can make simple requests" do
      url = "#{base_url}/boop"
      stub_request(:get, url)

      FastlyNsq::Http.new(uri: URI.parse(url)).get
      FastlyNsq::Http.new(uri: url).get

      expect(a_request(:get, url)).to have_been_requested.twice
    end

    it "can make requests with params" do
      url = "#{base_url}/boop?sloop=noop"
      data = {sloop: "noop"}
      stub_request(:get, url)

      FastlyNsq::Http.new(uri: url).get(data)

      expect(a_request(:get, url).with(query: data)).to have_been_made
    end
  end

  describe "post" do
    it "can make simple post requests" do
      url = "#{base_url}/boop?sloop=noop"
      stub_request(:post, url)
      data = {sloop: "noop"}

      FastlyNsq::Http.new(uri: URI.parse(url)).post(data)
      FastlyNsq::Http.new(uri: url).post(data)

      expect(a_request(:post, url)).to have_been_requested.twice
    end

    it "can make post requests with bodies" do
      url = "#{base_url}/boop?sloop=noop"
      stub_request(:post, url)
      data = {sloop: "noop"}
      body = "SOME MESSAGE"

      FastlyNsq::Http.new(uri: url).post(data, body)

      expect(a_request(:post, url).with(body: body)).to have_been_requested
    end
  end

  describe "SSL" do
    it "can be asked to use SSL" do
      ssl_url = "https://example.com:80/boop"
      stub_request(:get, ssl_url)

      cert_file = "/tmp/thing.cert"
      key_file = "/tmp/thing.key"

      allow(File).to receive(:read).with(cert_file).and_return("something")
      allow(File).to receive(:read).with(key_file).and_return("something")
      allow(OpenSSL::X509::Certificate).to receive(:new).with("something").and_return(true)
      allow(OpenSSL::PKey::RSA).to receive(:new).with("something").and_return(true)

      url = "#{base_url}/boop"
      http = FastlyNsq::Http.new(uri: url, cert_filename: cert_file, key_filename: key_file)
      http.use_ssl
      http.get

      expect(a_request(:get, ssl_url)).to have_been_requested
      expect(File).to have_received(:read).twice
      expect(OpenSSL::X509::Certificate).to have_received(:new)
      expect(OpenSSL::PKey::RSA).to have_received(:new)
    end
  end
end
