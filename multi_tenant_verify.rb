# multi_tenant_verify.rb

begin
  ActiveRecord::Base.transaction do
    puts "--- Setup ---"
    c1 = Company.create!(name: 'Company A', rut: '111-1')
    c2 = Company.create!(name: 'Company B', rut: '222-2')
    
    puts "Created companies: #{c1.name}, #{c2.name}"
    
    # Simulate User in Company A
    puts "--- Testing Company A ---"
    Current.company = c1
    
    # Create Vehicle for A
    v1 = Vehicle.create!(plate: 'PLATE-A', year: 2020)
    puts "Created Vehicle #{v1.plate} for #{v1.company.name}"
    
    raise "Vehicle not assigned to C1" unless v1.company == c1
    
    # Check visibility
    if Vehicle.count == 1 && Vehicle.first == v1
      puts "Visibility Correct: Company A sees only its vehicle."
    else
      puts "Visibility Error: Company A sees #{Vehicle.all.map(&:plate)}"
      exit 1
    end
    
    # Simulate User in Company B
    puts "--- Testing Company B ---"
    Current.company = c2
    
    # Create Vehicle for B
    v2 = Vehicle.create!(plate: 'PLATE-B', year: 2021)
    puts "Created Vehicle #{v2.plate} for #{v2.company.name}"
    
    # Check visibility
    visible = Vehicle.all
    if visible.count == 1 && visible.first == v2
      puts "Visibility Correct: Company B sees only its vehicle."
    else
      puts "Visibility Error: Company B sees #{visible.map(&:plate)}"
      exit 1
    end

    # Cross check
    if Vehicle.where(plate: 'PLATE-A').exists?
      puts "Security Breach: Company B can see PLATE-A!"
      exit 1
    else
      puts "Security Correct: Company B cannot see PLATE-A."
    end
    
    puts "\nALL TESTS PASSED"
    raise ActiveRecord::Rollback # clean up
  end
rescue => e
  puts "ERROR: #{e.message}"
  puts e.backtrace
end
