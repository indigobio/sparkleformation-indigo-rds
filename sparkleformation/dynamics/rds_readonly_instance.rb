SparkleFormation.dynamic(:rds_readonly_instance) do |_name, _config = {}|

  conditions.set!(
    "#{_name}_force_ssl".to_sym,
    equals!(ref!("#{_name}_only_speaks_ssl".to_sym), 'true')
  )

  parameters("#{_name}_publicly_accessible".to_sym) do
    type 'String'
    allowed_values %w(true false)
    default 'false'
    description 'Expose the DB instance to the Internet'
  end

  parameters("#{_name}_allocated_storage".to_sym) do
    type 'Number'
    min_value _config.fetch(:allocated_storage, 10)
    default _config.fetch(:allocated_storage, 10)
    description "The amount of allocated storage for the #{_name} database instance"
    constraint_description "Must be a number #{_config.fetch(:allocated_storage, 100)} or higher"
  end

  parameters("#{_name}_engine_version".to_sym) do
    type 'String'
    allowed_values registry!(:engine_versions, _config[:engine])
    default registry!(:latest_engine_version, _config[:engine])
  end

  parameters("#{_name}_allow_major_version_upgrade".to_sym) do
    type 'String'
    allowed_values %w(true false)
    default _config.fetch(:allow_major_version_upgrade, 'false').to_s
    description 'Allow major database version upgrades during maintenance'
  end

  parameters("#{_name}_auto_minor_version_upgrade".to_sym) do
    type 'String'
    allowed_values %w(true false)
    default _config.fetch(:auto_minor_version_upgrade, 'true').to_s
    description 'Automatically apply minor database version upgrades during maintenance'
  end

  parameters("#{_name}_d_b_instance_class".to_sym) do
    type 'String'
    allowed_values registry!(:rds_instance_types)
    default _config.fetch(:db_instance_class, 'db.t2.micro')
    description "Instance types to run the #{_name} database instance"
  end

  parameters("#{_name}_d_b_instance_identifier".to_sym) do
    type 'String'
    default "#{ENV['org']}-#{ENV['environment']}-#{_name}"
    allowed_pattern "[\\x20-\\x7E]*"
    description "RDS instance identifier"
    constraint_description 'can only contain ASCII characters'
  end

  parameters("#{_name}_only_speaks_ssl".to_sym) do
    type 'String'
    default _config.fetch(:force_ssl, 'true')
    allowed_values %w(true false)
    description 'Allow SSL-encrypted connections only'
  end

  dynamic!(:rds_force_ssl, _name, :engine => _config[:engine])

  dynamic!(:r_d_s_d_b_instance, _name).properties do
    allocated_storage ref!("#{_name}_allocated_storage".to_sym)
    allow_major_version_upgrade ref!("#{_name}_allow_major_version_upgrade".to_sym)
    auto_minor_version_upgrade ref!("#{_name}_auto_minor_version_upgrade".to_sym)
    d_b_instance_class ref!("#{_name}_d_b_instance_class".to_sym)
    d_b_instance_identifier _config[:db_instance_identifier]
    d_b_parameter_group_name if!("#{_name}_force_ssl", ref!("#{_name}_r_d_s_d_b_parameter_group".to_sym), no_value!)
    source_d_b_instance_identifier join!(['arn:aws:rds', region!, account_id!, 'db', ref!(_config[:source_db_instance_identifier])], {:options => { :delimiter => ':'}})
    v_p_c_security_groups _config.fetch(:vpc_security_groups, _array(ref!("#{_name}_ec2_security_group".to_sym)))
    d_b_subnet_group_name _config.fetch(:db_subnet_group, ref!("#{_name}_r_d_s_d_b_subnet_group".to_sym))
    engine _config[:engine]
    engine_version _config[:engine_version]
    storage_type _config[:storage_type]
    publicly_accessible ref!("#{_name}_publicly_accessible".to_sym)
    tags _array(
           -> {
             key 'Environment'
             value ENV['environment']
           }
         )
  end
end