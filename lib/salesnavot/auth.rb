module Salesnavot
  class Auth
    def initialize(session)
      @session = session
    end

    def login!(username, password)
      puts "visiting login screen"
      @session.visit("https://www.linkedin.com/sales")

      puts "adding email & password"
      @session.fill_in "Email", with: username
      @session.fill_in "Password", with: password

      puts "click login"
      @session.find('.btn-primary').click

      #We wait until de navbar appears
      while @session.all('.nav-item').count != 8
        puts "waiting for login"
        sleep(0.2)
      end
    end

  end
end
