class PublishArticleJob < ApplicationJob
  queue_as :default

  def perform(article_id)
    article = Article.find_by(id: article_id)
    return unless article && article.published_at <= Time.current

    article.update(comments_enabled: true, moderated: false) # Example: mark as published
  end
end
