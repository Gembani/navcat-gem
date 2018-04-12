module Salesnavot
  class Friends
    def initialize(session)
      @session = session
    end
    def scroll_to(element)
      script = <<-JS
        arguments[0].scrollIntoView(true);
      JS

      @session.driver.browser.execute_script(script, element.native)
    end
    def css(count)
      "section.mn-connections > ul >  li:nth-child(#{count+1})"
    end

    def get_next_block(count)
      block = @session.all(:css, css(count)).first
      if (block == nil)
        puts "block == nil: #{count}"
        scroll_to(@session.all(:css, css(count - 1)).first)
        while (@session.all(:css, css(count)).first == nil)
          puts "#{css(count)} not found"
          sleep(0.1)
        end
        block = @session.all(:css, css(count)).first
      end
      block
    end

    def execute(num_times = 40)
      init_list
      count = 0
      puts "execute find friends"
      num_times.times do
        block = get_next_block(count)
        name = block.find(".mn-connection-card__name").text
        time_ago = block.find(".time-ago").native.text
        yield time_ago, name
        count = count + 1
      end
    end

    def init_list
      puts "init list"
      @session.visit("https://www.linkedin.com/mynetwork/invite-connect/connections/")
      while (@session.all('.mn-connection-card').count == 0)
        puts ".mn-connection-card not found"
        sleep(0.1)
      end

    end

  end
end
