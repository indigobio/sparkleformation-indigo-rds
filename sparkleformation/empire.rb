SparkleFormation.new(:empire_rds, :provider => :aws).load(:base).overrides do
  description <<EOF
RDS instance for Empire. VPC security group. Route53 record (empire-rds.#{ENV['private_domain']}).
Send notifications to the #{ENV['org']}-#{ENV['environment']}-create-rds-db-instance SNS topic.
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

  # For Lambda
  dynamic!(:security_group_ingress, 'private-to-empire-rds-postgres',
           :source_sg => registry!(:my_security_group_id, 'private_sg'),
           :ip_protocol => 'tcp',
           :from_port => '5432',
           :to_port => '5432',
           :target_sg => attr!(:empireDB_ec2_security_group, 'GroupId')
          )

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
