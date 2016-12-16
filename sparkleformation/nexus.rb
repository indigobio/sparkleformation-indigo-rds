SparkleFormation.new(:nexus_rds, :provider => :aws).load(:base).overrides do
  description <<EOF
RDS instance for Nexus. Route53 record (nexus-rds.#{ENV['private_domain']}).
Send notifications to the #{ENV['org']}-#{ENV['environment']}-create-rds-db-instance SNS topic.
EOF

  ENV['app_username']                  ||= 'nexus'
  ENV['app_password']                  ||= 'nexus'
  ENV['source_db_instance_identifier'] ||= "#{ENV['org']}-prod-nexus"

  dynamic!(:db_subnet_group, 'nexus')

  dynamic!(:rds_db_instance,'nexus',
           :engine => 'postgres',
           :app_username => ENV['app_username'],
           :app_password => ENV['app_password'],
           :vpc_security_groups => _array(registry!(:my_security_group_id, 'private_sg')),
           :source_db_instance_identifier => ENV['source_db_instance_identifier']
          )

  dynamic!(:record_set, 'nexus',
           :record => 'nexus-rds',
           :target => :nexus_r_d_s_d_b_instance,
           :domain_name => ENV['private_domain'],
           :attr => 'Endpoint.Address',
           :ttl => '60'
          )

end