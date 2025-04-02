class ArticleSchedulerService
  def self.schedule(article, publish_at)
    article.update!(published_at: publish_at)
  end
end
