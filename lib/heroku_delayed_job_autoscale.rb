require 'rubygems'
require 'heroku_delayed_job_autoscale/managers/local'
require 'heroku_delayed_job_autoscale/managers/heroku'
require 'heroku_delayed_job_autoscale/managers/stub'

module HerokuDelayedJobAutoscale
  module Autoscale

    @@autoscale_manager = HerokuDelayedJobAutoscale::Manager::Local
    @@recurring_job_count = RecurringJob.subclasses.count

    def self.autoscale_manager
      @@autoscale_manager
    end

    def self.autoscale_manager=(manager)
      @@autoscale_manager = manager
    end

    def enqueue(job)
      autoscale_enqueue(job)
    end

    def autoscale_enqueue(job)
      begin
        # only autoscale for non recurring jobs and there is a max of 4 workers
        if !job.ancestors.include?(RecurringJob) && autoscale_client.qty < 5
          autoscale_client.scale_up
        end
      rescue Exception => e
        Rails.logger.error "Error autoscaling heroku workers: #{e}"
      end
    end

    def perform
      raise "Not implemented"
    end

    def after(job)
      autoscale_after(job)
    end

    def autoscale_after(job)
      begin
        # after is triggered before the job is removed
        # we scale down unless there are no non-recurring jobs left and we make sure
        # there is always 1 worker left
        if job.class.count - @@recurring_job_count > 0 && autoscale_client.qty > 1
          autoscale_client.scale_down
        end
      rescue Exception => e
        Rails.logger.error "Error autoscaling heroku workers: #{e}"
      end
    end

    protected
      def autoscale_client
        @autoscale_client ||= @@autoscale_manager.new
      end

  end
end
