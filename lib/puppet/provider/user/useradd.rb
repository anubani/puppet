require 'puppet/provider/nameservice/objectadd'

Puppet::Type.type(:user).provide :useradd, :parent => Puppet::Provider::NameService::ObjectAdd do
    desc "User management via ``useradd`` and its ilk.  Note that you'll have to install the ``Shadow Password`` library to manage user passwords."

    commands :add => "useradd", :delete => "userdel", :modify => "usermod"

    options :home, :flag => "-d", :method => :dir
    options :comment, :method => :gecos
    options :groups, :flag => "-G"

    verify :gid, "GID must be an integer" do |value|
        value.is_a? Integer
    end

    verify :groups, "Groups must be comma-separated" do |value|
        value !~ /\s/
    end

    has_features :manages_homedir, :allows_duplicates

    if Puppet.features.libshadow? and case Facter.value(:kernel)
        when "Linux": true
        else
            false
        end

        has_features :manages_passwords
    end

    def addcmd
        cmd = [command(:add)]
        @model.class.validproperties.each do |property|
            next if property == :ensure
            # the value needs to be quoted, mostly because -c might
            # have spaces in it
            if value = @model.should(property) and value != ""
                cmd << flag(property) << value
            end
        end

        if @model.allowdupe?
            cmd << "-o"
        end

        if @model.managehome?
            cmd << "-m"
        elsif %w{Fedora RedHat}.include?(Facter.value("operatingsystem"))
            cmd << "-M"
        end

        cmd << @model[:name]

        cmd
    end

    # Retrieve the password using the Shadow Password library
    def password
        if ent = Shadow::Passwd.getspnam(@model.name)
            return ent.sp_pwdp
        else
            return :absent
        end
    end
end

# $Id$
