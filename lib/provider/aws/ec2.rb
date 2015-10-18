module Provider
  module AWS
    class EC2
      attr_accessor :key_pair, :ec2, :instances,
        :instance, :image_id, :image,
        :wait_time, :wait, :server

      SECURITY_GROUPS = ["vz-cpw"]
      INSTANCE_TYPES  = ["t2.micro", "c1.medium", "m1.large"]

      # http://stackoverflow.com/questions/22365470/launching-instance-vpc-security-groups-may-not-be-used-for-a-non-vpc-launch
      TYPES = {
        "cpw" => {
          security_groups: "vz-cpw",
          instance_type:   "c1.medium",  # "t2.micro",
          key_name:        "vz-cpw-ec2",
          subnet_id:       "subnet-20054d79",
          # network_interfaces: [{
          #   subnet_id: 'subnet-20054d79',
          #   device_index: 0,
          #   associate_public_ip_address: true
          # }],
          user_data:
<<-eos
#!/bin/bash
cd && ./vz-cpw/bin/server/restart
eos
        }
      }

      def launch(params = {})
        type  = params[:type] || @type
        raise "You must pass a machine type, e.g. #{TYPES.inspect}" if !type || !TYPES[type]

        count   = params[:count] || 1
        wait    = params[:wait] || @wait
        @image  = ec2.images[params[:image]] if params[:image]
        @image  ||= get_latest_image(type)

        raise "Missing image!  The latest image could not be found!" unless @image and @image.exists?

        launch_params = TYPES[type]

        launch_params.merge!({
          count: count,
          key_pair: @key_pair,
          image_id: @image.id,
        })

        @instance = @ec2.instances.create(launch_params)

        return @instance unless wait

        wait_time = @wait_time
        while wait_time > 0
          puts "Waiting for instance to start...#{@instance.id}, status: #{@instance.status}"
          sleep(30)
          wait_time = wait_time - 30
          break if @instance.status == :running
        end
        raise "Instance failed to start in appropriate time!" if wait_time <= 0

        @instance
      end

      def get_latest_image(type = @type)
        raise "Invalid type #{type}, e.g. #{TYPES.inspect}" unless TYPES.include?(type)
        regexp = /#{type}/i
        result, last_time = nil, 10.years.ago

        @ec2.images.tagged("Name").each do |image|
          name_tag = image.tags["Name"]
          if image.name.match(regexp) || name_tag.match(regexp)
            time = Time.parse(image.creation_date)
            last_time, result = time, image if time > last_time
          end
        end
        result
      end

      def set_image(image_id)
        @image = @ec2.images[image_id]
        raise "Image #{@image_id} not found!" unless @image.exists?
        @image
      end

      private

      def initialize(params = {})
        kp = Rails.env.production? ? "vz-cpw-ec2" : "vz-cpw-ec2"
        @key_pair   = ::AWS::EC2::KeyPair.new(kp)
        @ec2        = ::AWS::EC2.new
        @instances  = Array.new
        @instance   = nil
        @image_id   = params[:image_id]
        @wait_time  = params[:wait_time] || 600
        @wait       = (not params[:wait] == false)

        set_image(@image_id) if @image_id

        if params[:instance_id]
          @instance = @ec2.instances[params[:instance_id]]
          raise "Instance #{params[:instance_id]} not found!" unless @instance
          @instances.push(@instance)
        end
      end
    end # EC2
  end # AWS
end # Provider