# Create ULID functions for every SQLite connection
ActiveSupport::Notifications.subscribe("sql.active_record") do |name, start, finish, id, payload|
  # Only process connection events for SQLite
  if payload[:connection]&.adapter_name == "SQLite"
    db = payload[:connection].raw_connection

    # Create the ULID generation functions if they don't exist
    begin
      # Test if function exists by trying to call it
      db.get_first_value("SELECT ULID()")
    rescue SQLite3::SQLException
      # Function doesn't exist, create it
      db.create_function("ULID", 0) do |func|
        func.result = ULID.generate
      end
    end

    begin
      # Test if prefixed function exists
      db.get_first_value("SELECT ULID_WITH_PREFIX('test')")
    rescue SQLite3::SQLException
      # Function doesn't exist, create it
      db.create_function("ULID_WITH_PREFIX", 1) do |func, prefix|
        func.result = "#{prefix}_#{ULID.generate}"
      end
    end
  end
end
