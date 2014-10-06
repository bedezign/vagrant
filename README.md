# Vagrant	


Some of my Vagrant helper tools


## Why?
I really don't like port numbers in the URLs on my test servers and wanted to make it look as close to real as possible. So I started looking for a way to map my vagrant hosts/ports on a "real domain", for which I don't need internet connectivity. I ended up with the scripts in this repository. They might not be useful for you as they are, but that is how they work for me.

## Scripts

### network.sh

The `network.sh` script is responsible adding the hostsnames to your system and making sure the declared ports are available on a unique port on the `lo` interface.
You modify it with the hosts you need and their last IP byte. Optionally you can modify the ports you want to map. If you do, make sure they don't overlap. The script will still work but you'll get very weird results :)


How it works:

 * First, an IP is added as an alias to your `lo` interface. The default IP is `172.16.190.1` for the first host (up to `.10`)
 * Then the script adds adds forwards for all defined ports per IP. So if the mapping is `80 => 2000`, port `80` of the first host will be mapped to port `2001` on localhost. 2000 as base + 1 for the last byte of host 1. Similarly port `22` will be mapped to `2011` and so on.
 * Lastly, your `/etc/hosts` is modified with the correct IP mappings so your system knows the DNS names. 

#### vagrant setup

In your `Vagrantfile` all that remains is to add mappings for the given ports to that virtual machine, no extra work needed:

 	# Disable the original 2222 entry
    config.vm.network :forwarded_port, :guest => 22,   :host => 2222, :id => "ssh", :disabled => "true"
    # Add forwards
    config.vm.network :forwarded_port, :guest => 80,   :host => 2001      # HTTP
    config.vm.network :forwarded_port, :guest => 22,   :host => 2011      # SSH
    config.vm.network :forwarded_port, :guest => 3306, :host => 2021      # MYSQL
  
 Congratulations, after a reboot of your vagrant VM, you now have a domain name assigned to it.
 
  

