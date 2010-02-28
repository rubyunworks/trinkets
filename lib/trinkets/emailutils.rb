begin
  require 'facets/net/smtp_tls'
rescue LoadError
  require 'net/smtp'
end

#module Rivets
  module EmailUtils

    module_function

    # Email function to easily send out an email.
    #
    # Settings:
    #
    #     subject      Subject of email message.
    #     from         Message FROM address [email].
    #     to           Email address to send announcemnt.
    #     server       Email server to route message.
    #     port         Email server's port.
    #     domain       Email server's domain name.
    #     account      Email account name.
    #     login        Login type: plain, cram_md5 or login [plain].
    #     secure       Uses TLS security, true or false? [false]
    #     message      Mesage to send -or-
    #     file         File that contains message.
    #
    # (Square brackets indicate defaults taken from Project information.
    # if used via Project class.)

    def email(message, settings)
      server    = settings['server']
      account   = settings['account']
      login     = settings['login'].to_sym
      subject   = settings['subject']
      mail_to   = settings['to']     || settings['mail_to']
      mail_from = settings['from']   || settings['mail_from']
      secure    = settings['secure']
      domain    = settings['domain'] || server

      port    ||= (secure ? 465 : 25)
      account ||= mail_from
      login   ||= :plain

      #mail_to = nil if mail_to.empty?

      raise ArgumentError, "missing email field -- server"  unless server
      raise ArgumentError, "missing email field -- account" unless account
      raise ArgumentError, "missing email field -- subject" unless subject
      raise ArgumentError, "missing email field -- to"      unless mail_to
      raise ArgumentError, "missing email field -- from"    unless mail_from

      passwd = password(account)

      mail_to = [mail_to].flatten.compact

      msg = ""
      msg << "From: #{mail_from}\n"
      msg << "To: #{mail_to.join(';')}\n"
      msg << "Subject: #{subject}\n"
      msg << ""
      msg << message

      begin
        Net::SMTP.enable_tls if Net::SMTP.respond_to?(:enable_tls) and secure
        Net::SMTP.start(server, port, domain, account, passwd, login) do |s|
          s.send_message( msg, mail_from, mail_to )
        end
        puts "Email sent successfully to #{mail_to.join(';')}."
        return true
      rescue => e
        if trace?
          raise e
        else
          abort "Email delivery failed."
        end
      end
    end

    #def password( account )
    #  @password || ENV['PASSWORD'] || ask("Password for #{account}: ")
    #end

  end
#end
