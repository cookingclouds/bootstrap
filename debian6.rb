bash -c '
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
  cd /tmp
  if [ -f /usr/bin/ruby1.9.1 ]; then
	rm /usr/bin/ruby
	ln -s /usr/bin/ruby1.9.1 /usr/bin/ruby
  fi
  if [ ! -f /usr/bin/gem ]; then
    CURRENTGEM=$(curl <%= "--proxy=on " if knife_config[:bootstrap_proxy] %> http://rubygems.org/pages/download 2>/dev/null|grep -A1 "download\">Download RubyGems")
    CURRENTGEM=$(echo $CURRENTGEM |tail -1)
    CURRENTGEM=$(echo $CURRENTGEM |cut -d\< -f 6 )
    CURRENTGEM=$(echo $CURRENTGEM | cut -dv -f 2)
    curl <%= "--proxy=on " if knife_config[:bootstrap_proxy] %> -O http://production.cf.rubygems.org/rubygems/rubygems-${CURRENTGEM}.tgz
    tar xzvf rubygems-${CURRENTGEM}.tgz
    cd rubygems-${CURRENTGEM}/
    ruby setup.rb --no-rdoc --no-ri --no-format-executable
  fi
fi

gem update --system
gem update
gem install ohai --no-rdoc --no-ri --verbose
gem install chef --no-rdoc --no-ri --verbose <%= bootstrap_version_string %>

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
