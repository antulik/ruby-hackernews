module HackerNews
  class Comment
    include Enumerable

    attr_reader :text
    attr_reader :text_html
    attr_reader :voting
    attr_reader :user
    attr_reader :children

    attr_accessor :parent

    def initialize(text_html, voting, user_info, reply_link, comment_link, parent_link)
      @text_html = text_html
      @voting = voting
      @user = user_info
      @reply_link = reply_link
      @comment_link = comment_link
      @parent_link = parent_link

      @children = []
    end

    def parent_id
      if parent
        parent.id
      elsif @parent_link
        @parent_link[/\d+/]
      end
    end

    def text
      @text ||= text_html.gsub(/<.{1,2}>/, "")
    end

    def id
      @comment_link[/\d+/] if @comment_link
    end

    def <<(comment)
      comment.parent = self
      @children << comment
    end

    def each(&block)
      @children.each(&block)
    end

    def <=>(other_comment)
      return other_comment.voting.score <=> @voting.score
    end

    def method_missing(method, *args, &block)
      @children.send(method, *args, &block)
    end

    def self.newest(pages = 1)
      return CommentService.new.get_new_comments(pages)
    end

    def self.newest_with_url(pages, url = nil)
      if url.nil?
        return CommentService.new.get_new_comments_with_url(pages)
      else
        return CommentService.new.get_new_comments_with_url(pages, url)
      end
    end

    def reply(text)
      return false unless @reply_link
      CommentService.new.write_comment(@reply_link, text)
      return true
    end

    def upvote
      VotingService.new.vote(@voting.upvote)
    end

    def downvote
      VotingService.new.vote(@voting.downvote)
    end

  end
end
