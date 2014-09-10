require 'rubygems'
require 'commander/import'

program :name, 'BitPay Ruby Library CLI'
program :version, BitPay::VERSION
program :description, 'Official BitPay Ruby API Client.  Use to securely register your client with the BitPay API endpoint. '
program :help_formatter, :compact
 
command :register_client do |c|
  c.syntax = 'bitpay register_client [options]'
  c.summary = 'Generate URL for registering client'
  c.description = 'Generates a registration URL to connect the client to a BitPay merchant account.  Uses private key from local ENV '\
    'variable PRIV_KEY or from ~./bitpay/api.key.\n  Using the --new_key option will generate a new key at ~./bitpay/api.key. '\
    'and use this to register the client.\n\n'\
    'Use the --label option to pass an identifier for the client that will appear in your BitPay API Client management page.'

  c.option '--silent', "Disable interactive mode"
  c.option '--uri <uri>', "API Endpoint URI to which the client should be registered (default 'https://bitpay.com')"
  c.option '--label <label>', "The desired label for the client on the BitPay merchant interface (default HOSTNAME)"
  c.option '--facade <facade>', "The facade to which the client is requesting permission (default 'pos')"
  c.option '--new_key', "Generate a new keypair before registering"
  c.option '--sin <sin>', "specify explicit SIN to register"
  
  c.example "Register a new POS client with the BitPay test environment", "bitpay register_client --uri 'https://test.bitpay.com'"\
    "--label 'My test client' --new_key"  
  
  c.action do |args, options|
    options.default \
      :uri => "https://bitpay.com",
      :label => "hostname", #TODO: replace this with actual hostname if possible
      :facade => "pos",
      :sin => BitPay::KeyUtils.get_sin
    
    unless options.silent   
      options.uri = ask("URI for BitPay Environment?  ") do |q|
        q.default = options.uri
        q.validate = lambda { |url| url =~ /\A#{URI::regexp(['http', 'https'])}\z/}
        q.responses[:not_valid] = "Please provide a valid URL"
      end
      options.label = ask("Label for client?  ") {|q| q.default = options.label}
      options.facade = ask("Which facade?  ") {|q| q.default = options.facade; q.in = %w[admin client finance merchant ops payroll pos support user]}
      options.sin = ask("SIN to register?  ") {|q| q.default = options.sin}
    end  

    url = BitPay::KeyUtils.generate_registration_url(options.uri,options.label,options.facade,options.sin)
    
    puts "\n\n"
    puts "BitPay API Client Registration:\n\n"
    puts "    Client Label:  #{options.label}"
    puts "      BitPay URI:  #{options.uri}"
    puts "          Facade:  #{options.facade}"
    puts "             SIN:  #{options.sin}"
    puts "\n  To register this client, please paste the URL below into a browser and login to your BitPay account"\
      " to approve access.\n"
    puts "\n    #{url}\n\n"

  end
end

command :show_keys do |c|
  c.syntax = 'bitpay show_keys'
  c.summary = "Read current environment's key information to STDOUT"
  c.description = ''
  c.example 'description', 'command example'
  c.action do |args, options|
    
    private_key   = BitPay::KeyUtils.get_local_private_key
    public_key    = BitPay::KeyUtils.get_public_key(private_key)
    sin           = BitPay::KeyUtils.get_sin(private_key)
    
    puts "Current BitPay Client Keys:\n"
    puts "Private Key:  #{private_key}"
    puts "Public Key:   #{public_key}"
    puts "SIN:          #{sin}"
    
  end
end