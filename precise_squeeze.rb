<%= "export http_proxy=\"#{knife_config[:bootstrap_proxy]}\"" if knife_config[:bootstrap_proxy] -%>

(
cat <<'EOP'
gem: --bindir=/usr/bin --no-ri --no-rdoc
EOP
) > /tmp/gemrc
awk NF /tmp/gemrc > /etc/gemrc
rm /tmp/gemrc

if [ ! -f /usr/bin/chef-client ]; then
  apt-get update
  apt-get install -y ruby1.9.1-dev build-essential wget
fi

gem update
gem install ohai --verbose
gem install chef --verbose <%= bootstrap_version_string %>

mkdir -p /etc/chef

(
cat <<'EOP'
<%= validation_key %>
EOP
) > /tmp/validation.pem
awk NF /tmp/validation.pem > /etc/chef/validation.pem
rm /tmp/validation.pem

<% if @chef_config[:encrypted_data_bag_secret] -%>
(
cat <<'EOP'
<%= encrypted_data_bag_secret %>
EOP
) > /tmp/encrypted_data_bag_secret
awk NF /tmp/encrypted_data_bag_secret > /etc/chef/encrypted_data_bag_secret
rm /tmp/encrypted_data_bag_secret
<% end -%>

(
cat <<'EOP'
<%= config_content %>
EOP
) > /etc/chef/client.rb

(
cat <<'EOP'
<%= { "run_list" => @run_list }.to_json %>
EOP
) > /etc/chef/first-boot.json

<%= start_chef %>'
