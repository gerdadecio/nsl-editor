
#
# Names can copy their instances
module Name::InstancesCopyable
  extend ActiveSupport::Concern

  def standalone_instances
    instances.select {|i| i.instance_type.standalone?}
  end

  def standalone_instances_sorted
    standalone_instances.sort_by {|si| si.reference&.iso_publication_date.to_s}
  end

  def standalone_instance_ids
    standalone_instances.map {|si| si.id}
  end

  def verified_requested_instances(requested_instance_ids)
    standalone_instances.select {|x| requested_instance_ids.include?(x.id.to_s)}
  end

  def copy_standalone_instances(target_name, requested_instance_ids, as_username)
    copy_tally = 0
    Name.transaction do
      verified_requested_instances(requested_instance_ids).each do |instance|
        instance.copy_to_new_name(target_name.id, as_username)  
        copy_tally += 1
      end
    end
    copy_tally
  end
end

