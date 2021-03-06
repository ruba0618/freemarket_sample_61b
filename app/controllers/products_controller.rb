class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :destroy, :edit, :update]
  before_action :set_pulldown, only: [:search, :detail_search]
  before_action :set_search_word, only: [:search, :detail_search]
  before_action :authenticate_user!, only: [:new]
  before_action :sold_products_record, only: [:index]
  before_action :title_word

  def index
    # トップページに表示する未取引の商品のレコードを取得(商品数が少ないためロジックはコメントアウト)
    # @not_sold_products = Product.includes(:photos).where.not(id: @sold_product_ids)
    @products = Product.includes(:photos)
    # 人気の４カテゴリとブランドのレコードを取得(※レコードの順番は人気順ではないことに注意)
    @popular_categories = Category.where(id: top4(category_root_ids))
    @popular_brands = Brand.where(id: top4(@sold_products_record.pluck(:brand_id)))
  end

  def show
    @title = @title_first + Product.find(params[:id]).name
    # 商品数カウント
    @product_count=Product.includes(:photos).count()
    # 出品者の商品から最新6件取得
    @user_products = Product.includes(:photos).where(user_id: @product.user_id).order('created_at DESC').limit(6)
    # クリックされた商品名と同じものを取得
    @same_name_products = Product.includes(:photos).where('name like ?',"%#{@product.name}%").limit(6)
  end

  def new
    @title = "出品" + @title_end + " " + @title_introduction
    @product = Product.new
    @product.photos.new
    @product.build_brand
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to root_path, notice: "商品を出品しました"
    else
      flash.now[:alert] = "商品の出品に失敗しました"
      render :new
    end
  end

  def edit
    @title = "商品の編集" + @title_end + " " + @title_introduction
    @delivery_method =  get_delivery_method
    @photos = Photo.where(product_id: @product.id).order("id ASC")
    @upper_photos = @photos.limit(5)
    @down_photos = Photo.where(product_id: @product.id).order("id DESC").limit(@photos.length - 5)

    # カテゴリプルダウンリストの中身
    @current_category = Category.find(@product.category_id)
    @root_categories = Category.where(ancestry: nil)
    @child_categories = @current_category.root.children
    @grandchild_categories = @current_category.parent.children
  end

  def update
    product = Product.new(product_params)
    if @product.user_id == current_user.id
      @product.update(product_update_params)
      redirect_to product_path, notice: "商品情報を更新しました"
    else
      @photos = Photo.where(product_id: @product.id)
      flash.now[:alert] = "商品情報の更新に失敗しました"
      render :edit
    end
  end

  def destroy
    if @product.destroy
      redirect_to root_path, notice: "商品を削除しました"
    else
      flash.now[:alert] = "商品の削除に失敗しました"
      render :show
    end
  end

  def search
    @title = @search_word + @title_introduction_other
    #検索ワード入力時、スペースを半角スペースに変換して、splitメソッドで検索ワードを配列に格納
    @search_words = @search_word.gsub(/[[:blank:]]/, " ").split(" ")
    @search_words.each do |search_word|
      @search_result = Product.all.includes(:photos, :brand, :category, :transaction_record).search(search_word).limit(132)
    end
    #検索ワードが空の場合、新着商品のデータを取得
    @products_new = Product.all.includes(:photos, :brand, :category, :transaction_record).order('created_at DESC')
  end

  def detail_search
    @title = "商品検索結果【Fmarket】No.2フリマアプリ"
    # # カテゴリー検索 get_categoryはcategory.rbに定義
    selected_category_id = params[:category_id].to_i
    category_ids = Category.get_category(selected_category_id)

    # #ブランド検索 get_brandはbrand.rbに定義
    input_brand_name = params[:brand_name]
    brand_ids = Brand.get_brand(input_brand_name)
    
    # サイズで検索 get_sizeはsize.rbに定義
    selected_size_id = params[:size_id]
    size_ids = Size.get_size(selected_size_id)

    #価格検索 set_min_price、set_max_priceはapplication.rbに定義
    input_min_price = params[:min_price]
    min_price = ApplicationRecord.set_min_price(input_min_price)
    input_max_price = params[:max_price]
    max_price = ApplicationRecord.set_max_price(input_max_price)

    # 商品の状態で検索 get_conditionはcondition.rbに定義
    checked_condition_ids = params[:condition_id]
    condition_ids = Condition.get_condition(checked_condition_ids)
   
    # #配送料の負担方法で検索 get_delivery_expenseはdelivery_expense.rbに定義
    checked_delivery_expense_ids = params[:delivery_expense_id]
    delivery_expense_ids = DeliveryExpense.get_delivery_expense(checked_delivery_expense_ids)

    # 販売状況で検索 get_statusはstatus.rbに定義
    checked_status_ids = params[:status_id]
    status_ids = Status.get_status(checked_status_ids)

    @search_words = params[:detail_search_word].gsub(/[[:blank:]]/, " ").split(" ")
    if @search_words.blank?
      @search_words = [""]
    end
    @search_words.each do |search_word|
      @search_result = Product.all.includes(:photos, :brand, :category, :transaction_record).search(search_word).where(
                                                                        category_id: category_ids, 
                                                                        brand_id: brand_ids, 
                                                                        size_id: size_ids,
                                                                        price: min_price..max_price,
                                                                        condition_id: condition_ids,
                                                                        delivery_expense_id: delivery_expense_ids,
                                                                        status_id: status_ids
                                                               )
    end
   @products_new = Product.includes(:photos, :brand, :category).order('created_at DESC')
  end

  # 親カテゴリーが選択された後に動くアクション
  def get_category_children
    #選択された親カテゴリーに紐付く子カテゴリーの配列を取得
    @category_children = Category.find_by(id: "#{params[:parent_id]}", ancestry: nil).children
  end

  # 子カテゴリーが選択された後に動くアクション
  def get_category_grandchildren
    #選択された子カテゴリーに紐付く孫カテゴリーの配列を取得
    @category_grandchildren = Category.find("#{params[:child_id]}").children
  end

  def get_size
    @sizes =  Size.all
  end
  
  # 配送料の負担が選択された後に動くアクション
  def get_delivery_method
    @delivery_method = if params[:delivery_expense_id] == "1"
                         DeliveryMethod.all
                       else
                         DeliveryMethod2.all
                       end
  end
  private

  def product_params
    params.require(:product).permit(:name, :description, :category_id, :size_id, :condition_id,
                                    :delivery_expense_id, :delivery_method_id, :area_id,
                                    :shipdate_id, :price, :status_id, photos_attributes: [:photo],
                                    brand_attributes: [:name]).merge(user_id: current_user.id)
  end

  def product_update_params
    params.require(:product).permit(:name, 
                                    :description,
                                    :size_id,
                                    :category_id,
                                    :condition_id,
                                    :delivery_expense_id,
                                    :delivery_method_id,
                                    :area_id,
                                    :shipdate_id,
                                    :price,
                                    brand_attributes: [:name],
                                    photos_attributes: [:photo, :_destroy, :id])
  end

  def set_pulldown
    @price_list = ["300 ~ 1000",
                   "1000 ~ 5000",
                   "5000 ~ 10000",
                   "10000 ~ 30000",
                   "30000 ~ 50000",
                   "50000 ~ 100000"]

    @list_change = ["価格の安い順",
                    "価格の高い順",
                    "出品の新しい順",
                    "いいね！の多い順"]
  end

  def set_product
    @product = Product.includes(:photos).find(params[:id])
  end 

  def set_search_word
    if params[:product].present?
      @search_word = params[:product][:search_word]
    else 
      @search_word = params[:search_word]
    end
    @detail_search_word = params[:detail_search_word]
  end

  private

  def sold_products_record
    # 取引された商品のIDを配列で取得
    @sold_product_ids = TransactionRecord.pluck(:product_id)
    @sold_products_record = Product.where(id: @sold_product_ids)
  end
  
  def category_root_ids
    # 取引された商品のカテゴリIDを取得
    sold_category_ids = @sold_products_record.pluck(:category_id)
    # sold_category_idsをルートIDに変換(メソッドはcategoryモデルに記載)
    Category.conversion_root_ids(sold_category_ids)
  end

  def top4(duplicate_ids)
    # 配列の重複数を計算。多い順にハッシュに格納
    duplicate_id_ranks = duplicate_ids.group_by(&:itself).map { |id, i| [id, i.count] }.sort_by { |_id, total| total }.reverse.to_h
    duplicate_id_ranks.keys[0..3]
  end
end
