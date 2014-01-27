#
# rake_template.rake
# Last Modified: 1/27/2014
# David Benko
# MIT License
#

###########################################
#                                         #
# Run With Command:                       #
# => run rake run_scheduled_task         #
#                                         #
###########################################

task :scheduled_task => :environment do
  # Actual task code goes here
end

# Wrapper for error catching 
# (This is the rake you will run)
# `run rake {name below here}` 
task :run_scheduled_task => :environment do
  include AP::EmailExtension::Email
  # Define max attempts 
  max_attempts = 5
  attempts = 0
  begin
    # Run task
    Rake::Task["scheduled_task"].invoke
    # Email Success
    setting = Utility.latest_version_object_class('Setting').first(:email_type => 'deployment')
    Resque.enqueue(LifecycleTriggeredEmailExtension, {"object_instance_id" => setting.id, "object_instance_id_field" => "id", "klass_name" => setting.class.name, "options" => {to_address: setting.email_to, from_address: setting.email_from, subject: setting.subject, outgoing_message_format: setting.body}})
  rescue Exception => e
    p "A crash: #{e}"
    if (attempts < max_attempts)
      attempts += 1
      retry
    else
      # Email Failure  
      setting = Utility.latest_version_object_class('Setting').first(:email_type => 'deployment_failure')
      Resque.enqueue(LifecycleTriggeredEmailExtension, {"object_instance_id" => setting.id, "object_instance_id_field" => "id", "klass_name" => setting.class.name, "options" => {to_address: setting.report_email_failure, from_address: setting.from_email, subject: setting.subject, outgoing_message_format: setting.body}})
    end  
  end
end
