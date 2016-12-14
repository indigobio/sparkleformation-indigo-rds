SparkleFormation.new(:empire_rds, :provider => :aws).load(:base).overrides do
  description <<EOF
RDS instance for Empire, a VPC, and a Route53 entry (empire-rds.#{ENV['private_domain']})
EOF

  ENV['app_username']                  ||= 'empire'
  ENV['app_password']                  ||= 'empirepass'
  ENV['source_db_instance_identifier'] ||= "#{ENV['org']}-prod-empire"

  parameters(:vpc) do
    type 'String'
    default registry!(:my_vpc)
    allowed_values array!(registry!(:my_vpc))
  end

  dynamic!(:vpc_security_group, 'empireDB', :ingress_rules => [])

  dynamic!(:db_subnet_group, 'empire')

  dynamic!(:rds_db_instance, 'empire',
           :engine => 'postgres',
           :app_username => ENV['app_username'],
           :app_password => ENV['app_password'],
           :vpc_security_groups => _array(ref!(:empireDB_ec2_security_group)),
           :source_db_instance_identifier => ENV['source_db_instance_identifier']
          )

  dynamic!(:record_set, 'empire',
           :record => 'empire-rds',
           :target => :empire_r_d_s_d_b_instance,
           :domain_name => ENV['private_domain'],
           :attr => 'Endpoint.Address',
           :ttl => '60'
          )
end
