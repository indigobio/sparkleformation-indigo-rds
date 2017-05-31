SparkleFormation.new(:comparator_rds, :provider => :aws).load(:base, :git_rev_outputs).overrides do
  description <<EOF
RDS instance for Comparator.  Route53 record (comparator-rds.#{ENV['private_domain']}).do
Send notifications to the #{ENV['org']}-#{ENV['environment']}-create-rds-role SNS topic.
EOF

  ENV['app_username']                  ||= 'comparator'
  ENV['app_password']                  ||= 'comparator'
  ENV['source_db_instance_identifier'] ||= "#{ENV['org']}-prod-comparator"

  dynamic!(:db_subnet_group, 'comparator')

  dynamic!(:rds_db_instance, 'comparator',
           :engine => 'postgres',
           :multi_az => 'false',
           :app_username => ENV['app_username'],
           :app_password => ENV['app_password'],
           :vpc_security_groups => _array(registry!(:my_security_group_id, 'private_sg')),
           :source_db_instance_identifier => ENV['source_db_instance_identifier']
          )

  dynamic!(:record_set, 'comparator',
           :record => 'comparator-rds',
           :target => :comparator_r_d_s_d_b_instance,
           :domain_name => ENV['private_domain'],
           :attr => 'Endpoint.Address',
           :ttl => '60'
          )
end
