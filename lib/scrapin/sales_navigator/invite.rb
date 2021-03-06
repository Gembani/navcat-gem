# frozen_string_literal: true

module ScrapIn
  module SalesNavigator
    # Goes to a lead profile page, and invite the lead
    class Invite
      include Tools
      include CssSelectors::SalesNavigator::Invite
      attr_reader :error
      def initialize(sales_nav_url, session, content, send = true)
        @sales_nav_url = sales_nav_url
        @session = session
        @error_types = %i[already_pending out_of_network already_friends email_required invitation_form_did_not_close no_pending_after]
        @error_messages = {
          already_pending: 'Invitation is already pending ...',
          out_of_network: 'Lead is out of network.',
          already_friends: 'Already friends',
          email_required: "Lead's email is required to connect",
          invitation_form_did_not_close: 'Invitation form did not close',
          no_pending_after: "Can't find pending connection button"
        }
        @error = nil
        @content = content
        @send = send
      end

      def error_message
        return nil if @error.nil?

        @error_messages[@error]
      end

      def execute
        if @sales_nav_url.include?('OUT_OF_NETWORK')
          @error = :out_of_network
          return false
        end
        visit_target_page(@sales_nav_url)
        if initially_pending?
          @error = :already_pending
          return false
        end
        find_and_click(@session, action_button_css)
        if friend?
          @error = :already_friends
          return false
        end
        return false unless click_and_connect
        return false unless invitation_window_closed?

        return false if @send && !pending_after_invite?

        lead_invited?
      end

      private

      def visit_target_page(link)
        @session.visit(link)
        raise CssNotFound, profile_css unless @session.has_selector?(profile_css)
      end

      def friend?
        raise CssNotFound, degree_css unless @session.has_selector?(degree_css, wait: 4)
        return true if @session.find(degree_css).text == '1st'

        false
      end

      def lead_email_required?
        return true if @session.has_selector?(form_email_css, wait: 3)

        false
      end

      def invitation_window_closed?
        # This wasn't working without the sleep as the window didn't have time to close so we put in
        # into a loop that check for 5 seconds (5000*1ms) and returns true the moment it stops seeing the window
        # We used a loop instead of a sleep on its own so it wouldn't wait if not needed
        5000.times do
          return true unless @session.has_selector?(form_css)

          sleep(0.001)
        end
        @error = :invitation_form_did_not_close
        false
      end

      def click_and_connect
        find_and_click(@session, action_button_css)
        puts 'clicking on the Connect button'
        find_and_click(@session, connect_button_css)
        if lead_email_required?
          @error = :email_required
          return false
        end
        @session.fill_in form_invitation_id, with: @content
        puts 'Sending invitation message'
        find_and_click(@session, send_button_css) if @send
        puts 'Message sent' if @send
        find_and_click(@session, '.artdeco-modal__dismiss') unless @send
        true
      end

      def initially_pending?
        find_and_click(@session, action_button_css)
        @session.has_selector?('li', text: pending_connection_css, wait: 4)
      end

      def pending_after_invite?
        find_and_click(@session, action_button_css)
        unless @session.has_selector?('li', text: pending_connection_css, wait: 4)
          @error = :no_pending_after
          return false
        end
        true
      end

      def lead_invited?
        visit_target_page(@sales_nav_url)
        true
      end
    end
  end
end
