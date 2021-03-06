# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScrapIn::SalesNavigator::ScrapMessages do
  
  include CssSelectors::SalesNavigator::ScrapMessages
  include ScrapIn::Tools

  def create_conversation(array)
    array.each_with_index do |element, count|
      has_selector(element, content_css, wait: 5)
      has_selector(element, sender_css, wait: 2, visible: false)

      content = { 'innerHTML' => message_content(count) }
      content = { 'innerHTML' => 'beginnning of the conversation' } if count.zero?

      # Alternate senders to see incoming and outgoing directions
      sender = count.even? ? { 'innerHTML' => '   You   ' } : { 'innerHTML' => '   Sender   ' }
      allow(element).to receive(:find).with(content_css, wait: 5).and_return(content)
      allow(element).to receive(:first).with(sender_css, wait: 2, visible: false).and_return(sender)
    end
  end
  let(:session) { instance_double('Capybara::Session', 'session') }
  let(:sales_messages) { instance_double('Capybara::Node::Element', 'sales_messages') }
  let(:message_thread) { instance_double('Capybara::Node::Element', 'message_thread') }

  let(:subject) do
    described_class
  end

  let(:salesnav_messages_instance) do
    subject.new(session, thread_link)
  end

  let(:message_thread_elements) { [] }
  let(:sales_loaded_messages) { [] }
  let(:bigger_conversation) { [] }

  let(:thread_link) { 'Conversation link to scrap' }

  before do
    # For more clear and fast results without all the logs nor sleeps
    disable_method(:puts)
    disable_script

    visit_succeed(thread_link)
    allow(session).to receive(:has_selector?).and_return(true)

    create_node_array(message_thread_elements, 5, 'message_thread_elements') # Create empty conversation thread
    message_thread_elements.each do |node|
      allow(node).to receive(:native) # Method used by scroll_up_to
    end
    create_node_array(sales_loaded_messages, 1, 'sales_loaded_messages') # Create at least one message to load
    # otherwise infinite loop to load conversation
    create_conversation(message_thread_elements) # Create a conversation in an array with messages and senders

    has_selector(message_thread, message_thread_elements_css, wait: 5)
    has_selector(sales_messages, message_thread_css, wait: 5)

    allow(message_thread).to receive(:first).with(message_thread_elements_css, wait: 5).and_return(message_thread_elements[0])
    allow(message_thread).to receive(:all).with(message_thread_elements_css, wait: 5)
                                          .and_return(message_thread_elements) # Return the messages array
    allow(sales_messages).to receive(:find).with(message_thread_css, wait: 5).and_return(message_thread)

    allow(session).to receive(:all).with(loaded_messages_css, wait: 5).and_return(sales_loaded_messages)
    # Return array of loaded messages to avoid infinite loop
    allow(session).to receive(:first).with(messages_css, wait: 5).and_return(sales_messages)
    # Return node for messages

    allow(session).to receive(:current_url).and_return(thread_link)
  end

  describe '.initialize' do
    it { is_expected.to eq ScrapIn::SalesNavigator::ScrapMessages }
  end

  describe '.execute' do
    context 'when everything is ok in order to scrap conversation messages' do
      context 'when all the messages have been loaded' do
        it 'puts successfully messages and direction and returns true' do
          count = 4 # because the conversation size is 5 (-1, the first one does not count)
          result = salesnav_messages_instance.execute(10) do |message, direction|
            expect(message).to eq(message_content(count))
            if count.even?
              expect(direction).to eq(:outgoing)
            else
              expect(direction).to eq(:incoming)
            end
            count -= 1
          end
          expect(result).to be(true)
        end
      end

      context 'when need to load more messages' do
        before do
          create_node_array(bigger_conversation, 10)
          bigger_conversation.each do |node|
            allow(node).to receive(:native) # Method used by scroll_up_to
          end
          create_conversation(bigger_conversation)
          allow(message_thread).to receive(:all)
            .with(message_thread_elements_css, wait: 5)
            .and_return(message_thread_elements, bigger_conversation)
        end
        it 'puts successfully messages and direction and returns true' do
          count = 10 - 1
          result = salesnav_messages_instance.execute(10) do |message, direction|
            expect(message).to eq(message_content(count))
            if count.even?
              expect(direction).to eq(:outgoing)
            else
              expect(direction).to eq(:incoming)
            end
            count -= 1
          end
          expect(result).to be(true)
        end
      end

      context 'when execute with 0 messages expected' do
        it 'returns true' do
          result = salesnav_messages_instance.execute(0) { |message, direction| }
          expect(result).to be(true)
        end
      end

      context 'when execute with no number of messages argument' do
        it 'returns true' do
          count = 5 - 1
          result = salesnav_messages_instance.execute do |message, direction|
            expect(message).to eq(message_content(count))
            if count.even?
              expect(direction).to eq(:outgoing)
            else
              expect(direction).to eq(:incoming)
            end
            count -= 1
          end
          expect(result).to be(true)
        end
      end
      context 'when execute with negative number of messages argument' do
        it { expect(salesnav_messages_instance.execute(-1000) { |message, direction| }).to be(true) }
      end
    end

    context 'when cannot wait message to appear' do
      context 'when cannot load messages' do
        before { allow(session).to receive(:all).with(loaded_messages_css, wait: 5).and_return([]) }
        it do
          expect { salesnav_messages_instance.execute(1) { |_message, _direction| } }
            .to raise_error('Cannot scrap conversation. Timeout !')
        end
      end
    end

    context 'when cannot find the sales_message_css' do
      before { has_not_selector(session, messages_css, wait: 5) }
      it do
        expect { salesnav_messages_instance.execute(1) { |_message, _direction| } }.to raise_error(ScrapIn::CssNotFound)
      end
      it do
        expect { salesnav_messages_instance.execute(1) { |_message, _direction| } }
          .to raise_error(/#{messages_css}/)
      end
    end

    context 'when cannot find the message_thread_css' do
      before { has_not_selector(sales_messages, message_thread_css, wait: 5) }
      it do
        expect { salesnav_messages_instance.execute(1) { |_message, _direction| } }.to raise_error(ScrapIn::CssNotFound)
      end
      it do
        expect { salesnav_messages_instance.execute(1) { |_message, _direction| } }
          .to raise_error(/#{message_thread_css}/)
      end
    end

    context 'when cannot find the message_thread_elements_css and cannot find first message to scroll' do
      before do
        has_not_selector(message_thread, message_thread_elements_css, wait: 5)
        allow(message_thread).to receive(:all).with(message_thread_elements_css, wait: 5).and_return([])
      end
      it do
        expect { salesnav_messages_instance.execute(1) { |_message, _direction| } }.to raise_error(ScrapIn::CssNotFound)
      end
      it do
        expect { salesnav_messages_instance.execute(1) { |_message, _direction| } }.to raise_error(/#{message_thread_elements_css}/)
      end
    end

    context 'when cannot find the content_css' do
      before do
        message_thread_elements.each do |message|
          has_not_selector(message, content_css, wait: 5)
        end
      end
      it do
        expect { salesnav_messages_instance.execute(1) { |_message, _direction| } }.to raise_error(ScrapIn::CssNotFound)
      end
      it do
        expect { salesnav_messages_instance.execute(1) { |_message, _direction| } }.to raise_error(/#{content_css}/)
      end
    end

    context 'when cannot find the sender_css' do
      before do
        message_thread_elements.each do |message|
          has_not_selector(message, sender_css, wait: 2, visible: false)
        end
      end
      it do
        expect { salesnav_messages_instance.execute(1) { |_message, _direction| } }.to raise_error(ScrapIn::CssNotFound)
      end
      it do
        expect { salesnav_messages_instance.execute(1) { |_message, _direction| } }.to raise_error(/#{sender_css}/)
      end
    end
    context 'when we give a name to execute method to check the lead name' do
      let(:lead_name_node) { instance_double('Capybara::Node::Element', 'lead_name') }
      let(:lead_name) { 'STOCK Nicholas' }
      before do
        has_selector(session, lead_name_css)
        allow(session).to receive(:find).with(lead_name_css).and_return(lead_name_node)
        allow(lead_name_node).to receive(:text).and_return(lead_name)
      end
      context 'when we give the correct one' do
        it 'returns true without raising an error' do
          expect(salesnav_messages_instance.execute(1, 'STOCK Nicholas') { |_message, _direction| }).to be(true)
        end
      end
      context 'when we give a wrong one' do
        it do
          expect do
            salesnav_messages_instance.execute(1, 'CEBULA Sébastien') { |_message, _direction| }
          end
            .to raise_error(ScrapIn::LeadNameMismatch)
        end
      end
    end
  end
end
