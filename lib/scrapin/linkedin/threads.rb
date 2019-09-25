module ScrapIn
  module LinkedIn
    class Threads
      include Tools
      include CssSelectors::LinkedIn::Threads
      def initialize(session)
        @session = session
      end

       def execute(num_times = 10)
        return true if num_times.zero?
        
        visit_messages_link
        count = 0

        num_times.times.each do
          item_limit = set_limit
          if count >= item_limit
            puts 'reach max open conversations'
            break
          else
            byebug
            conversation = find_conversation(count)
            return false if conversation == false

            name = conversation.text
            conversation.click
            thread_link = @session.current_url
            yield name, thread_link
            count += 1
          end
          sleep(1.5)
        end
        true
        # count = 0

        #  num_times.times.each do
        # item = @session.all(threads_block_count_css(count)).first # verifie la count-ieme conversation
        # if item.empty?
        #   #count = 0 => css n'existe pas
        #   #count > 0 => css existe mais il n'y a plus de conversations
        # end

        # name = check_and_find(item, one_thread_css).text
        # byebug
        # # thread_link = check_and_find(item, href_css)[:href]
        # thread_link = @session.current_url
        # byebug
        # yield name, thread_link
        # scroll_to(item)
        # count += 1
        # #click au lieu de scroll => url change
        # sleep(0.5)
        # # byebug
        # true
      end

       def visit_messages_link
        @session.visit('https://www.linkedin.com/messaging/')
        # wait_messages_page_to_load
        puts 'Messages have been visited.'
      end

      # def wait_messages_page_to_load
      #   time = 0
      #   byebug
      #   while @session.all(message_css, wait: 5).count < 2
      #     puts 'Waiting messages to appear'
      #     sleep(0.2)
      #     time += 0.2
      #     raise 'Cannot scrap conversation. Timeout !' if time > 60
      #   end
      # end

      def find_conversation(count)
        threads_list = check_and_find(@session, threads_list_css)
        threads_list_elements = threads_list.all(threads_list_elements_css, wait: 5)[count]
        return false if threads_list_elements.nil?

        check_and_find(threads_list_elements, thread_name_css, wait: 5)
      end

      def set_limit
        threads_list = check_and_find(@session, '.msg-conversations-container__conversations-list')
        threads_list.all('.msg-conversation-listitem', wait: 5).count
      end
    end
  end
end 