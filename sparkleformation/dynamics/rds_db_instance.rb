SparkleFormation.dynamic(:rds_db_instance) do |_name, _config = {}|

  _config[:db_instance_identifier] ||= "#{ENV['org']}-#{ENV['environment']}-#{_name}"

  conditions.set!(
    "#{_name}_restore".to_sym,
    equals!(ref!("#{_name}_restore_from_snapshot".to_sym), 'true')
  )

  conditions.set!(
    "#{_name}_force_ssl".to_sym,
    equals!(ref!("#{_name}_only_speaks_ssl".to_sym), 'true')
  )

  parameters("#{_name}_restore_from_snapshot".to_sym) do
    type 'String'
    allowed_values %w(true false)
    default _config.fetch(:restore_from_snapshot, 'true').to_s
    description 'Restore from RDS snapshot'
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

  parameters("#{_name}_multi_a_z".to_sym) do
    type 'String'
    allowed_values %w(true false)
    default _config.fetch(:multi_az, 'true')
    description 'Set up a multi-AZ RDS instance'
  end

  parameters("#{_name}_d_b_name".to_sym) do
    type 'String'
    default _name
    allowed_pattern "[\\x20-\\x7E]*"
    description "Name of the #{_name} database instance"
    constraint_description 'can only contain ASCII characters'
  end

  parameters("#{_name}_master_username".to_sym) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default ENV.fetch('master_username', 'root')
    description "Master username for the #{_name} database instance"
    constraint_description 'can only contain ASCII characters'
  end

  parameters("#{_name}_master_password".to_sym) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default registry!(:random_password)
    description "Master password for the #{_name} database instance"
    constraint_description 'can only contain ASCII characters'
  end

  parameters("#{_name}_app_username".to_sym) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default _config.fetch(:app_username, _name)
    description "Application username for the #{_name} database instance"
    constraint_description 'can only contain ASCII characters'
  end

  parameters("#{_name}_app_password".to_sym) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default _config.fetch(:app_password, _name)
    description "Application username for the #{_name} database instance"
    constraint_description 'can only contain ASCII characters'
  end

  parameters("#{_name}_snapshot_id".to_sym) do
    type 'String'
    allowed_values registry!(:all_rds_snapshots, _config[:source_db_instance_identifier])
    default registry!(:latest_rds_snapshot, _config[:source_db_instance_identifier])
    description 'RDS snapshot to restore'
  end

  parameters("#{_name}_allocated_storage".to_sym) do
    type 'Number'
    min_value _config.fetch(:allocated_storage, 10)
    default _config.fetch(:allocated_storage, 10)
    description "The amount of allcoated storage for the #{_name} database instance"
    constraint_description "Must be a number #{_config.fetch(:allocated_storage, 100)} or higher"
  end

  parameters("#{_name}_backup_retention_period".to_sym) do
    type 'Number'
    min_value _config.fetch(:backup_retention_period, 1)
    default _config.fetch(:backup_retention_period, 7)
    description "Number of days to keep backups of the #{_name} database instance"
    constraint_description "Must be a number #{_config.fetch(:backup_retention_period, 1)} or higher"
  end

  parameters("#{_name}_storage_encrypted".to_sym) do
    type 'String'
    default _config.fetch(:storage_encrypted, 'true')
    allowed_values %w(true false)
    description 'Encrypt storage'
  end

  parameters("#{_name}_storage_type".to_sym) do
    type 'String'
    default _config.fetch(:storage_type, 'gp2')
    allowed_values %w(gp2 io1)
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
    backup_retention_period ref!("#{_name}_backup_retention_period".to_sym)
    v_p_c_security_groups _config.fetch(:vpc_security_groups, _array(ref!("#{_name}_ec2_security_group".to_sym)))
    d_b_subnet_group_name _config.fetch(:db_subnet_group, ref!("#{_name}_r_d_s_d_b_subnet_group".to_sym))
    d_b_instance_class ref!("#{_name}_d_b_instance_class".to_sym)
    d_b_instance_identifier _config[:db_instance_identifier]
    d_b_parameter_group_name if!("#{_name}_force_ssl", ref!("#{_name}_r_d_s_d_b_parameter_group".to_sym), no_value!)
    # if
    d_b_snapshot_identifier if!("#{_name}_restore".to_sym, ref!("#{_name}_snapshot_id".to_sym), no_value!)
    # else
    d_b_name if!("#{_name}_restore".to_sym, no_value!, ref!("#{_name}_d_b_name".to_sym))
    engine if!("#{_name}_restore".to_sym, no_value!, _config[:engine])
    engine_version if!("#{_name}_restore".to_sym, no_value!, ref!("#{_name}_engine_version".to_sym))
    master_username if!("#{_name}_restore".to_sym, no_value!, ref!("#{_name}_master_username".to_sym))
    master_user_password if!("#{_name}_restore".to_sym, no_value!, ref!("#{_name}_master_password".to_sym))
    storage_encrypted if!("#{_name}_restore".to_sym, no_value!, ref!("#{_name}_storage_encrypted".to_sym))
    # end
    storage_type _config[:storage_type]

    multi_a_z ref!("#{_name}_multi_a_z".to_sym)
    tags _array(
           -> {
             key 'Environment'
             value ENV['environment']
           },
           -> {
             key 'AppUsername'
             value ref!("#{_name}_app_username".to_sym)
           },
           -> {
             key 'AppPassword'
             value ref!("#{_name}_app_password".to_sym)
           }
         )
  end
end