require 'heroku'

module HerokuDelayedJobAutoscale
  module Manager
    class Heroku
      def initialize(options={})
        username = options[:username] || ENV['HEROKU_USERNAME']
        password = options[:password] || ENV['HEROKU_PASSWORD']
        @app     = options[:app]      || ENV['HEROKU_APP']
        @client = ::Heroku::Client.new(username, password)
      end

      def qty
        @client.info(@app)[:workers].to_i
      end

      def scale_up
        @client.set_workers(@app, +1)
      end

      def scale_down
        @client.set_workers(@app, -1)
      end
    end
  end
end