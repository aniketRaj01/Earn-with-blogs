class ArticlesController < ApplicationController
  before_action :require_authentication
  def show
    @article = Article.find(params[:id])
    render json: {"article": @article, likes: @article.likes, comments: @article.comments}
  end

  def index
    @articles = Article.all
    article = []
    @articles.each do |obj|
    article << {"article": obj, "likes": obj.likes, "comments": obj.comments}
    end
    render json: article
  end

  def new
    @article = Article.new
  end

  def edit
    @article = Article.find(params[:id])
  end

  def update
    @article = Article.find(params[:id])
    if @article.user != @current_user
      return render json: {msg: "you are not author of article"}
    end
    if @article.update(params.require(:article).permit(:title, :description))
      render json: @article, status: :ok
    else
      render json: {errors: @article.errors.full_messages}
    end
  end
  
  protect_from_forgery with: :null_session # For APIs, we disable CSRF protection

  def create
    @article = Article.new(article_params)
    @article.user = @current_user
    if @article.save
      render json: @article, status: :created
    else
      render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @article = Article.find(params[:id])
    if @article.user != @current_user
      return render json: {msg: "you are not author of article"}
    end
    if @article.destroy
      render json: {msg: "given article deleted succesfully"}, status: :ok
    else
      render json: {errors: @article.errors.full_messages}, status: :no_content
    end
  end

  private
  def article_params
    params.require(:article).permit(:title, :description, :topic)
  end

  def require_authentication
    header = request.headers['Authorization']
    token = header.split(' ').last if header

    begin
      decoded_token = JWT.decode(token, 'your_secret_key', true, algorithm: 'HS256')
      render json: {error: "invalid token"} if !decoded_token[0]['user_id']
      @current_user = User.find(decoded_token[0]['user_id'])
    rescue JWT::DecodeError
      render json: { error: header }, status: :unauthorized
    end
  end
  # config/application.rb or config/initializers/cors.rb
end