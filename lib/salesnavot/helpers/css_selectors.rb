module CssSelectors
  module Friends
    def friend_name_css
      '.mn-connection-card__name'
    end

    def time_ago_css
      '.time-ago'
    end

    def nth_friend_css(count)
      "section.mn-connections > ul >  li:nth-child(#{count + 1})"
    end

    def connections_url(*args)
      'https://www.linkedin.com/mynetwork/invite-connect/connections/'
    end
  end
end
