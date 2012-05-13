require 'redis'

# TODO: test performance
# TODO: write tests; run tests

module Rack

  ##
  # Rack middleware for protecting against Denial-of-service attacks
  # http://en.wikipedia.org/wiki/Denial-of-service_attack.
  #
  # This middleware is designed for small deployments, which most likely
  # are not utilizing load balancing from other software or hardware. 
  # Using Redis as the backend is particularly useful in cloud hosting environments
  # like Heroku and others where the only shared information between the nodes
  # is the network attached database.
  #
  # Deflect currently supports the following functionality:
  #
  # * Saturation prevention (small DoS attacks, or request abuse)
  # * Blocking from the apps response (via special headers)
  # * Whitelisting of known good remote addresses
  # * Applies only for given REQUEST_METHODS (defaults to all types)
  # * Logging
  # * Falling back to block / allow all when redis fails
  #
  # === Options:
  #
  #   :log                When false logging will be bypassed, otherwise pass an object responding to #puts
  #   :log_format         Alter the logging format
  #   :log_date_format    Alter the logging date format
  #   :request_threshold  Number of requests allowed within the set :interval. Defaults to 100
  #   :interval           Duration in seconds until the request counter is reset. Defaults to 5
  #   :block_duration     Duration in seconds that a remote address will be blocked. Defaults to 900 (15 minutes)
  #   :skip_for           Array of remote addresses which bypass Deflect. NOTE: this does not block others
  #   :default_block      When true, blocks requests when redis failed for whatever reason
  #   :request_methods    Regexp object. This middleware is only applied if the regexp matches the request method
  #
  # === Examples:
  #
  #  use Rack::DeflectRedis, :log => $stdout, :request_threshold => 20, :interval => 5, :block_duration => 60
  #  This will deny all requests for 60 secounds after 20 requests were made within 5 secs.
  #
  # CREDIT: Marvin Frick <marv@hostin.is> based on Rack::Deflect by TJ Holowaychuk <tj@vision-media.ca>
  #

  class DeflectRedis

    attr_reader :options

    def initialize app, options = {}
      @app, @options = app, {
        :log => false,
        :log_format => 'deflect_redis(%s): %s',
        :log_date_format => '%m/%d/%Y',
        :request_threshold => 100,
        :interval => 5,
        :block_duration => 900,
        :skip_for => [],
        :default_block => false,
        :request_methods => /.*/,
        :redis_host => "127.0.0.1",
        :redis_port => 6379,
        :redis_db => 0,
        :redis_timeout => 5, 
        :redis_password => nil
      }.merge(options)
      
      #begin
        @redis = Redis.new  :host => @options[:redis_host],
                            :port => @options[:redis_port],
                            :db => @options[:redis_db],
                            :timeout => @options[:redis_timeout],
                            :password => @options[:redis_password]
      #rescue 
      #  puts "WARNING: Rack::DeflectRedis could not connect to redis! Blocking all requests per default: #{@options[:default_block].to_s}"
      # OMG REDIS Y U NO RAISE EXCEPTION!?!?
      #  @redis = nil
      #end

    end

    def call env
      return deflect! if deflect? env
      status,  headers, body = @app.call env
      # block this remote_addr if app ask us to
      block!(request.ip) if headers['X-Rack::DeflectRedis'] == "block!"
      headers.delete('X-Rack::DeflectRedis')
      [status, headers, body]
    end

    def deflect!
      [403, { 'Content-Type' => 'text/plain', 'Content-Length' => '0' }, []]
    end

    def deflect? env
      begin
        @remote_addr = request.ip
        unless @options[:skip_for].include? @remote_addr or not(env['REQUEST_METHOD'] =~ @options[:request_methods])
        
          # increases counter for this remote_add
          # and if it is the first request from this addr
          # set the key timeout to :intervall
          count = @redis.incr(@remote_addr).to_i
          if count == 1
            @redis.expire(@remote_addr, @options[:interval])
        
          elsif count > @options[:request_threshold]
          
            # or if the count of requests > threshold => block it
            @redis.expire(@remote_addr, @options[:block_duration])
            log "blocking #{@remote_addr} for pushing too far"
            return true
          end
        end
      rescue 
        return @options[:default_block]
      end
      false
    end

    def log message
      return unless options[:log]
      options[:log].puts(options[:log_format] % [Time.now.strftime(options[:log_date_format]), message])
    end
  

    def block!(remote_addr)
      log "force blocking of #{@remote_addr} for #{@options[:block_duration].to_s}"
      @redis.set(@remote_addr,999999)
      @redis.expire(@remote_addr, @options[:block_duration])
    end

  end
end
