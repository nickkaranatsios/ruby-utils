require 'net/ldap'
host="localhost"
dn = "cn=, dc=, dc=com"
attr = {
  :card_id => "11223344",
  :objectclass => "gatecontrol"
}
dn = "cn=George Smith, ou=people, dc=WORKGROUP"
attr = {
  :cn => "George Smith",
  :objectclass => ["top", "inetorgperson"],
  :sn => "Smith",
  :mail => "gsmith@example.com"
}
Net::LDAP.open(:host => host) do |ldap|
  res = ldap.add(:dn => dn, :attributes => attr)
  puts "add result #{res}"
end
exit


treebase = "dc= dc="
filter = Net::LDAP::Filter.eq("card_id", "11*")
attrs = [:card_id]
Net::LDAP.open(:host => host) do |ldap|
  res = ldap.delete(:dn => dn)
  puts "ldap deleted #{res}"
  res = ldap.add(:dn => dn, :attributes => attr)
puts "added #{res}"

  ldap.search(:base => treebase, :attributes => attrs,
            :return_result => false) do |entry|
    puts "DN: #{entry.dn}"
    entry.each do |attr, values|
      puts ".......#{attr}:"
      values.each do |value|
        puts "          #{value}"
      end
    end
  end
end

