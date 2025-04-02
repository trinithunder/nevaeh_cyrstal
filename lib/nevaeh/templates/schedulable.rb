module Schedulable
  extend ActiveSupport::Concern

  included do
    scope :scheduled, -> { where("published_at > ?", Time.current) }
    scope :published, -> { where("published_at <= ?", Time.current) }

    after_save :schedule_publication, if: -> { published_at.present? }
  end

  private

  def schedule_publication
    return if published_at.past?

    PublishArticleJob.set(wait_until: published_at).perform_later(self.id)
  end
end
