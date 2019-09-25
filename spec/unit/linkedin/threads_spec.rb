require 'spec_helper'

RSpec.describe ScrapIn::LinkedIn::Threads do
	RSpec::Mocks.configuration.allow_message_expectations_on_nil = true
	let(:subject) do
		described_class
	end

	let(:linkedin_threads_instance) do
		subject.new(session)
	end

	let(:session) { instance_double('Capybara::Session') }
	let(:messages_link) { 'https://www.linkedin.com/messaging/' }
	let(:thread_name) { instance_double('Capybara::Node::Element', 'thread_name') }
	let(:thread_link) { instance_double('Capybara::Node::Element', 'thread_link') }
	let(:item_href_hash) { { href: 'https://www.linkedin.com/messaging/threads/johnsmith' } }
	let(:threads_block_array) { [] }
	let(:item_array) { [] }
	let(:item) {}

	include CssSelectors::LinkedIn::Threads

	before do
		disable_puts
		disable_script
		create_node_array(threads_block_array, 3)
		create_node_array(item_array, 12)

		allow(session).to receive(:visit).with(messages_link)

		
		count = 0
		12.times do 
			has_selector(session, threads_block_css)
			allow(session).to receive(:all).with(threads_block_css).and_return(threads_block_array)
			has_selector(session, threads_block_count_css(count))
			allow(session).to receive(:all).with(threads_block_count_css(count)).and_return(item_array)
			item = item_array[count]

			has_selector(item, one_thread_css)
			allow(item).to receive(:find).with(one_thread_css).and_return(thread_name)
			allow(thread_name).to receive(:text).and_return('John Smith')
			name = thread_name
			
			has_selector(item, href_css)
			allow(item).to receive(:find).with(href_css).and_return(thread_link)
			link = item_href_hash[:href]
			# byebug
			# thread_link[:href] = 'https://www.linkedin.com/messaging/threads/johnsmith'
			allow(thread_link).to receive([]).with(':href').and_return(link)
			byebug
			
			allow(item).to receive(:native)
			# puts(count)
			count += 1
		end
	end

	context 'testtesttest' do
		it 'testtesttest' do
			expect ( linkedin_threads_instance.execute { |_name, _thread_link| } )
				.to eq(true)
		end
	end

	# context 'the selector for threads block count was not found' do
	# 	before do
	# 		count = 0
	# 		12.times do
	# 			has_not_selector(session, threads_block_count_css(count))
	# 			count += 1
	# 		end
	# 	end
	# 	it do
	# 		12.times do
	# 			expect { linkedin_threads_instance.execute { |_name, _thread_link| } }
	# 				.to raise_error(ScrapIn::CssNotFound)
	# 			count += 1
	# 		end
	# 	end
	# 	it do
	# 		12.times do
	# 			expect { linkedin_threads_instance.execute { |_name, _thread_link| } }
	# 				.to raise_error(/#{threads_block_count_css}/)
	# 			count += 1
	# 		end
	# 	end
	# end

	# context 'the selector for threads block was not found' do
	# 	before { has_not_selector(session, threads_block_css) }
	# 	it do
	# 		expect { linkedin_threads_instance.execute { |_name, _thread_link| } }
	# 			.to raise_error(ScrapIn::CssNotFound)
	# 	end
	# 	it do
	# 		expect { linkedin_threads_instance.execute { |_name, _thread_link| } }
	# 			.to raise_error(/#{threads_block_css}/)
	# 	end
	# end

	# context 'the selector for one thread was not found' do
	# 	before { 			has_not_selector(session, threads_block_count_css(10))		}
	# 	it do
	# 		expect { linkedin_threads_instance.execute(12) { |_name, _thread_link| } }
	# 			.to raise_error(ScrapIn::CssNotFound)
	# 	end
	# 	it do
	# 		expect { linkedin_threads_instance.execute { |_name, _thread_link| } }
	# 			.to raise_error(/#{one_thread_css}/)
	# 	end
	# end

	# context 'the selector for href was not found' do
	# 	before { has_not_selector(item, href_css) }
	# 	it do
	# 		expect { linkedin_threads_instance.execute { |_name, _thread_link| } }
	# 			.to raise_error(ScrapIn::CssNotFound)
	# 	end
	# 	it do
	# 		expect { linkedin_threads_instance.execute { |_name, _thread_link| } }
	# 			.to raise_error(/#{href_css}/)
	# 	end
	# end
end