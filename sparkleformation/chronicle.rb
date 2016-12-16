SparkleFormation.new(:chronicle_rds, :provider => :aws).load(:base).overrides do
  description <<EOF
RDS instance for Chronicle. VPC security group for public instance. Route53 records (chronicle-rds.#{ENV['private_domain']}, chronicle-rds.#{ENV['public_domain']}).
Send notifications to the #{ENV['org']}-#{ENV['environment']}-create-rds-db-instance SNS topic.
EOF

  ENV['app_username']                  ||= 'chronicle'
  ENV['app_password']                  ||= 'chroniclepass'
  ENV['source_db_instance_identifier'] ||= "#{ENV['org']}-prod-chronicle"

  parameters(:vpc) do
    type 'String'
    default registry!(:my_vpc)
    allowed_values array!(registry!(:my_vpc))
  end

  parameters(:allow_postgres_from) do
    type 'String'
    allowed_pattern "(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})"
    default '127.0.0.1/32'
    description 'Network to allow postgres clients from, for Chronicle. Note that the default of 127.0.0.1/32 effectively disables postgres access.'
    constraint_description 'Must follow IP/mask notation (e.g. 192.168.1.0/24)'
  end

  # Internal db instance
  dynamic!(:vpc_security_group, 'chronicle', :ingress_rules => [])

  # For Lambda
  dynamic!(:security_group_ingress, 'private-to-chronicle-rds-postgres',
           :source_sg => registry!(:my_security_group_id, 'private_sg'),
           :ip_protocol => 'tcp',
           :from_port => '5432',
           :to_port => '5432',
           :target_sg => attr!(:chronicle_ec2_security_group, 'GroupId')
          )

  dynamic!(:db_subnet_group, 'chronicle')

  dynamic!(:rds_db_instance, 'chronicle',
           :engine => 'postgres',
           :app_username => ENV['app_username'],
           :app_password => ENV['app_password'],
           :vpc_security_groups => _array(ref!(:chronicle_ec2_security_group)),
           :source_db_instance_identifier => ENV['source_db_instance_identifier']
          )

  dynamic!(:record_set, 'chronicle',
           :record => 'chronicle-rds',
           :target => :chronicle_r_d_s_d_b_instance,
           :domain_name => ENV['private_domain'],
           :attr => 'Endpoint.Address',
           :ttl => '60'
          )

  # Public db instance

  dynamic!(:vpc_security_group, 'chroniclepublic', :ingress_rules => [
    { 'cidr_ip' => ref!(:allow_postgres_from), 'ip_protocol' => 'tcp', 'from_port' => '5432', 'to_port' => '5432' }
  ])

  dynamic!(:db_subnet_group, 'chroniclepublic',
           :subnets => registry!(:my_public_subnet_ids)
          )

  dynamic!(:rds_readonly_instance, 'chroniclepublic',
           :engine => 'postgres',
           :vpc_security_groups =>  _array(ref!(:chroniclepublic_ec2_security_group)),
           :source_db_instance_identifier => :chronicle_r_d_s_d_b_instance,
           :publicly_accessible => true
          )

  dynamic!(:record_set, 'chroniclepublic',
           :record => 'chronicle-rds',
           :target => :chroniclepublic_r_d_s_d_b_instance,
           :domain_name => ENV['public_domain'],
           :attr => 'Endpoint.Address',
           :ttl => '60'
          )
end
