module Ironfan
  class Provider

    class Ec2 < Ironfan::IaasProvider
      self.handle = :ec2

      def self.resources
        [ Machine, ElasticIp, EbsVolume, Keypair, SecurityGroup ]
      end

      #
      # Utility functions
      #
      def self.connection
        @@connection ||= Fog::Compute.new(self.aws_credentials.merge({ :provider => 'AWS' }))
      end

      def self.aws_account_id()
        Chef::Config[:knife][:aws_account_id]
      end

      # Ensure that a fog object (machine, volume, etc.) has the proper tags on it
      def self.ensure_tags(tags,fog)
        tags.delete_if {|k, v| fog.tags[k] == v.to_s  rescue false }
        return if tags.empty?

        Ironfan.step(fog.name,"tagging with #{tags.inspect}", :green)
        tags.each do |k, v|
          Chef::Log.debug( "tagging #{fog.name} with #{k} = #{v}" )
          Ironfan.safely do
            config = {:key => k, :value => v.to_s, :resource_id => fog.id }
            connection.tags.create(config)
          end
        end
      end

      def self.applicable(computer)
        computer.server and computer.server.clouds.include?(:ec2)
      end

      private

      def self.aws_credentials
        return {
          :aws_access_key_id     => Chef::Config[:knife][:euca_access_key_id],
          :aws_secret_access_key => Chef::Config[:knife][:euca_secret_access_key],
          :region                => Chef::Config[:knife][:region]
          :endpoint              => Chef::Config[:knife][:euca_api_endpoint]
        }
      end

    end
  end
end
