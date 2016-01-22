require 'net/http'
require 'uri'
require 'nokogiri'
require 'metainspector'

module Model::URI
  class TargetError < StandardError; end
  class InvalidTargetError < TargetError; end
  class TooManyRedirectsTargetError < TargetError; end

  class Target
    DEFAULT_USER_AGENT   = 'Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:10.0) Gecko/20100101 Firefox/10.0'
    KNOWN_HTTP_ERRORS    = {"401" => :not_authorized,
      "403" => :access_forbidden, "404" => :not_found,
      "408" => :request_timeout}
    KNOWN_MEDIA_SERVICES = {
      youtube: /^(?:https?:\/\/)?(?:www\.)?youtu(?:\.be|be\.com)\/(?:watch\?v=)?([\w-]{10,})/,
      google_drive: /^(?:https?:\/\/)?drive\.google\.com\/file\/d\/(.*?)/,
      dropbox: /^(?:https?:\/\/)?(?:www\.)?dropbox\.com\/s\/(.*?)/,
      facebook: /^(https?:\/\/www\.facebook\.com\/(?:video\.php\?v=\d+|.*?\/videos\/\d+))$/
    }

    attr_accessor :url, :header, :options

    delegate :content_type, to: :response, allow_nil: true

    def initialize(url, header = {}, options = {})
      @url, @options, @response = url, options, nil
      @header = { 'User-Agent' => DEFAULT_USER_AGENT }.merge(header)
    end

    def valid?
      !!(url =~ URI::DEFAULT_PARSER.regexp[:ABS_URI])
    end

    def resolves?
      response.try(:code).to_i >= 200 && response.try(:code).to_i < 300
    end

    def response
      @response ||= fetch
    rescue Net::HTTPServerException => ex
      @response
    rescue InvalidTargetError, TooManyRedirectsTargetError
      nil
    end

    def uri
      @uri ||= URI.parse(url) if url.present?
    end

    def media_service
      KNOWN_MEDIA_SERVICES.find {|t| t.last.match(uri.to_s)}.try(:first) if uri.present?
    end

    def valid_media_service?
      !!media_service
    end

    def valid_media_content_type?
      !!content_type && !!(content_type.match(/^(video)\/?.*$/i) || content_type.match(/^(audio)\/?.*$/i))
    end

    def metadata
      result = {}
      result['content_type'] = content_type if content_type

      if valid_media_content_type?
        # E.g. on 'video/mpeg' or 'audio/wav'
        result['title'] = uri.path.try(:split, "/").try(:last)
      elsif valid_media_service?
        # E.g. YouTube video
        page = MetaInspector.new(url, document: response.body)
        result['ms_name']       = media_service.to_s
        result['title']         = page.best_title
        result['description']   = page.description
        result['image']         = page.images.best
        result['keywords']      = Array.wrap(page.meta_tag['name']['keywords'].try(:split, ",")).map(&:strip).reject {|n| n.match(/\.\.\./)}
        result.merge!(page.meta_tags)
      end
      result.stringify_keys!
      result
    end

    def error
      key = KNOWN_HTTP_ERRORS[response.code] if response.code
      I18n.t(key, scope: [:lib, :model, :media_helper, :http_errors]) if key
    end

    private

    # Inspired by OpenURI::open_http
    # https://github.com/ruby/ruby/blob/trunk/lib/open-uri.rb
    def fetch(limit = 10)
      raise InvalidTargetError, 'not a valid URL' unless valid?
      raise TooManyRedirectsTargetError, 'too many redirects' if limit == 0

      http = Net::HTTP.new(uri.hostname, uri.port, nil)

      if uri.class == URI::HTTPS
        require 'net/https'
        http.use_ssl = true
        http.verify_mode = options[:ssl_verify_mode] || OpenSSL::SSL::VERIFY_PEER
        store = OpenSSL::X509::Store.new
        if options[:ssl_ca_cert]
          Array(options[:ssl_ca_cert]).each do |cert|
            if File.directory? cert
              store.add_path cert
            else
              store.add_file cert
            end
          end
        else
          store.set_default_paths
        end
        http.cert_store = store
      end

      http.start do
        request   = Net::HTTP::Get.new(uri.request_uri, header)
        @response = http.request request
        case response
          when Net::HTTPSuccess then response
          when Net::HTTPRedirection
            @url, @uri = response['location'], nil
            fetch(limit - 1)
        else
          response.error!
        end
      end
    end
  end
end