class ArticlesController < ApplicationController
  load_and_authorize_resource

  def create
    @article = current_user.articles.new(article_params)
    authorize! :create, @article
    if @article.save
      redirect_to @article, notice: "Article created successfully."
    else
      render :new
    end
  end

  def update
    authorize! :update, @article
    if @article.update(article_params)
      redirect_to @article, notice: "Article updated successfully."
    else
      render :edit
    end
  end

  private

  def article_params
    params.require(:article).permit(:title, :content, :blog_id, :published_at, :comments_enabled, :moderated)
  end
end
