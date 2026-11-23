if ENV.key?("SEED_ADMIN_EMAIL") || ENV.key?("SEED_ADMIN_PASSWORD")
  email = ENV.fetch("SEED_ADMIN_EMAIL").strip.downcase
  Administrator.find_or_create_by!(email:) do |administrator|
    administrator.name = ENV.fetch("SEED_ADMIN_NAME", "管理者")
    administrator.password = ENV.fetch("SEED_ADMIN_PASSWORD")
  end
end
