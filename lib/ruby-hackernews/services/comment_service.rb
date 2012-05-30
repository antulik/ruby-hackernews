module RubyHackernews
  class CommentService
    include RubyHackernews::MechanizeContext

    def get_comments(page_url)
      page = agent.get(page_url)
      table = page.search("table")[3]
      return get_comments_entities(table)
    end

    def get_user_comments(user)
      page = agent.get(ConfigurationService.base_url + "threads?id=#{user.name}")
      table = page.search("table")[2]
      return get_comments_entities(table)
    end

    def get_comments_entities(table)
      comments = []
      last   = comments
      current_level = -1
      table.search("table/tr").select do |tr|
        tr.search("span.comment").inner_html != "[deleted]"
      end.each do |tr|
        comment = parse_comment(tr)
        level = tr.search("img[@src='http://ycombinator.com/images/s.gif']").first['width'].to_i / 40
        difference = current_level - level
        target = last
        (difference + 1).times do
          target = target.parent || comments
        end
        return comments
      end

    def get_new_comments_with_url(pages = 1, url = ConfigurationService.comments_url)
      parser = EntryPageParser.new(agent.get(url))
      comments = []
      next_url = nil
      pages.times do
        lines = parser.get_lines
        lines.each do |line|
          comments << parse_comment(line)
        end
        next_url = parser.get_next_url || break
        parser = EntryPageParser.new(agent.get(next_url))
      end
      return {:comments => comments, :next_url => next_url}
    end

    def get_new_comments(pages = 1, url = ConfigurationService.comments_url)
      return get_new_comments_with_url(pages, url)[:comments]
    end

    def parse_comment(element)
      text = ""
      element.search("span.comment").first.children.each do |ch|
        text = ch.inner_html
      end
      header = element.search("span.comhead").first
      voting = VotingInfoParser.new(element.search("td/center/a"), header).parse
      user_info = UserInfoParser.new(header).parse

      reply_link = element.search("td[@class='default']/p//u//a").first
      reply_url = reply_link['href'] if reply_link

      comment_link = element.search("td[@class='default']//span[@class='comhead']/a[text()*='link']").first
      comment_url = comment_link['href'] if comment_link

      parent_link = element.search("td[@class='default']//span[@class='comhead']/a[text()*='parent']").first
      parent_url = parent_link['href'] if parent_link

      return Comment.new(text, voting, user_info, reply_url, comment_url, parent_url)
    end

    def write_comment(page_url, comment)
      require_authentication
      form = agent.get(page_url).forms.first
      form.text = comment
      form.submit
      return true
    end

  end
end