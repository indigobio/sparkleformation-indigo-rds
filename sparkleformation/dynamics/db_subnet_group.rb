SparkleFormation.dynamic(:db_subnet_group) do |_name, _config = {}|
  dynamic!(:r_d_s_d_b_subnet_group, _name).properties do
    d_b_subnet_group_description "#{_name}_db_subnet_group".gsub('-','_').to_sym
    subnet_ids _config.fetch(:subnets, registry!(:my_private_subnet_ids))
    tags _array(
           -> {
             key 'Name'
             value "#{_name}_db_subnet_group".gsub('-','_').to_sym
           },
           -> {
             key 'Environment'
             value ENV['environment']
           }
         )
  end
end