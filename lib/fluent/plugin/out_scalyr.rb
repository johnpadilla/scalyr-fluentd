
require 'set'
require 'securerandom'
require 'json'
require 'net/http'
require 'net/https'

module Scalyr
  class FluentLogger < Fluent::BufferedOutput
    Fluent::Plugin.register_output( 'scalyr', self )

    config_param :api_write_token, :string
    config_param :server_host, :string, :default => nil
    config_param :server_type, :string, :default => nil
    config_param :region, :string, :default => nil
    config_param :add_events, :string, :default => "https://www.scalyr.com/addEvents"

    def configure( conf )
      super
      @last_timestamp = 0
      @add_events_uri = URI @add_events
    end

    def start
      super
      @session = SecureRandom.uuid
    end

    def format( tag, time, record )
      [tag, time, record].to_msgpack
    end

    def write( chunk )
      thread_ids = Set.new

      events = Array.new

      chunk.msgpack_each {|(tag,time,record)|

        thread_ids.add( tag )

        timestamp = time * 10**9
        timestamp = [timestamp, @last_timestamp + 1].max
        @last_timestamp = timestamp

        events << { :thread => tag,
                    :ts => timestamp.to_s,
                    :attrs => record
                  }

      }

      threads = Array.new

      thread_ids.each do |thread|
        threads << { :id => thread,
                     :name => "Fluentd logs for the #{thread} tag"
                   }
      end

      current_time = Fluent::Engine.now * 10**6

      body = { :token => @api_write_token,
                  :client_timestamp => current_time.to_s,
                  :session => @session,
                  :events => events,
                  :threads => threads
                }

      if @session_info
        body[:sessionInfo] = @session_info
      end

      https = Net::HTTP.new( @add_events_uri.host, @add_events_uri.port )
      https.use_ssl = true

      post = Net::HTTP::Post.new @add_events_uri.path
      post.add_field( 'Content-Type', 'application/json' )
      post.body = body.to_json

      response = https.request( post )

      puts response


    end

  end
end