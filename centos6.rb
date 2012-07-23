bash -c '
<%= "export http_proxy=\"#{knife_config[:bootstrap_proxy]}\"" if knife_config[:bootstrap_proxy] -%>
RPMURL="http://ftp.osuosl.org/pub/fedora-epel/6/x86_64/"
RPMNAME=$(wget -qO- $RPMURL |grep epel |grep rpm |while read i ; do expr "$i" : '.*href="\(.*\)">.*'; done)

if [ ! -f /usr/bin/chef-client ]; then
  curl <%= "--proxy=on " if knife_config[:bootstrap_proxy] %> ${RPMURL}/${RPMNAME} -O
  rpm -Uvh $RPMNAME
  yum install -y ruby ruby-devel gcc gcc-c++ automake autoconf make
  cd /tmp
    CURRENTGEM=$(curl <%= "--proxy=on " if knife_config[:bootstrap_proxy] %> http://rubygems.org/pages/download 2>/dev/null|grep -A1 "download\">Download RubyGems")
    CURRENTGEM=$(echo $CURRENTGEM |tail -1)
    CURRENTGEM=$(echo $CURRENTGEM |cut -d\< -f 6 )
    CURRENTGEM=$(echo $CURRENTGEM | cut -dv -f 2)
  curl <%= "--proxy=on " if knife_config[:bootstrap_proxy] %>http://production.cf.rubygems.org/rubygems/rubygems-${CURRENTGEM}.tgz -O
  tar zxf rubygems-${CURRENTGEM}.tgz
  cd rubygems-${CURRENTGEM}
  ruby setup.rb --no-format-executable
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
