module Provider
  module AWS
    class CloudWatch
      attr_accessor :region, :object, :start_time_seconds

      DEFAULT_REGION     = 'us-east-1'
      START_TIME_SECONDS = 600

      STATS = {
        "AWS/EC2"      => ["CPUUtilization", "NetworkOut"],
        "AWS/ELB"      => ["Latency"],
        "AWS/DynamoDB" => ["ConsumedReadCapacityUnits"]
      }

      def get_ec2_stats(instances, params = {})
        statistics = {}
        dimensions = Array.wrap(instances).map {|s| {name: "InstanceId", value: "#{s.instance_id}"} }

        STATS["AWS/EC2"].each do |metric|
          cw_metric = ::AWS::CloudWatch::Metric.new("AWS/EC2", metric, dimensions: dimensions)
          stats     = cw_metric.statistics(start_time: (Time.zone.now - @start_time_seconds).iso8601, end_time: Time.zone.now.iso8601, statistics: ["Average"])
          if params[:all]
            statistics[metric] = stats.sort {|a,b| a[:timestamp] <=> b[:timestamp]}
          else
            statistics[metric] = stats.sort{|a,b| a[:timestamp] <=> b[:timestamp]}[-1]
          end
        end
        statistics
      end

      def region=(region)
        @region = region
        ::AWS.config(region: @region)
        @object = ::AWS::CloudWatch.new
      end

      private

      def initialize(region = DEFAULT_REGION)
        self.start_time_seconds = START_TIME_SECONDS
        self.region             = DEFAULT_REGION
      end

    end
  end
end