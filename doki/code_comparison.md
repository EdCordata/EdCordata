# **EdCordata** - Some code examples in other companies


```ruby
class CatalogueController < ApplicationController
  def index
    @banner = Banner.active.language(params[:locale]).location("catalogue").order("RAND()").first
    @products = get_all_products
  end

  def page
    page_offset = (params[:page_id].to_i - 1).abs * APP_DEFINITIONS[:catalogue][:products_per_page].to_i
    products = get_all_products(offset: page_offset)

    respond_to do |format|
      format.html do
        render partial: "products", locals: { products: products }
      end
    end
  end

  def sale
    unless params[:filters].blank?
      parameters = params[:filters].reject { |_, value| value == "none" }
      redirect_to catalogue_sale_path(parameters)
    end

    @banners = get_banners("sale")
    @products = get_products_by_filters.where("`store_sale_price` > 0").limit(nil)
    @total = @products.count

    @manufacturers = Manufacturer.published.order(:name)
  end

  def compare
    @banners = get_banners("comparison_results")
    @products = get_products_for_comparison
    @total = @products.count
  end

  def filters
    response = {}

    params[:usage] = "car" unless Usage.exists?(short_code: params[:usage].upcase)
    filters_type = Usage.find_by_short_code(params[:usage].upcase)

    filters_type_group = []

    if filters_type.parent.present?
      filters_type_group << filters_type.parent
      filters_type_group += filters_type.parent.children.try(&:active).to_a
    else
      filters_type_group << filters_type
      filters_type_group += filters_type.children.try(&:active).to_a
    end

    filters_season = convert_season_to_id(params[:season])
    filters_season = [Model::WINTER, Model::MS] if filters_season == Model::WINTER
    filters_season = nil if (%w[MOTO MOTOCROSS] & filters_type_group.map(&:short_code)).any?

    response[:widths] = Size.fetch_available_widths(filters_type_group, filters_season).uniq
    response[:manufacturers] = Manufacturer.fetch_available(filters_type_group, filters_season).order(:name)

    unless params[:width].nil?
      response[:heights] = Size.fetch_available_heights(filters_type_group, filters_season, params[:width]).uniq
      response[:diameters] = Size.fetch_available_diameters(filters_type_group, filters_season, params[:width], params[:height]).uniq unless params[:height].nil?
    end

    respond_to do |format|
      format.json { render json: response.to_json }
    end
  end

  def filtered
    unless params[:filters].blank?
      parameters = params[:filters].reject { |_, value| value == "none" }
      redirect_to catalogue_filtered_path(parameters)
    end

    @banners = get_banners("filtered_results")
    @products = get_products_by_filters
    @total = @products.count

    filters_type_group = Usage.get_with_siblings(params[:type] || "CAR")

    filters_season = convert_season_to_id(params[:season])
    filters_season = [Model::WINTER, Model::MS] if filters_season == Model::WINTER
    filters_season = nil if (%w[MOTO MOTOCROSS] & filters_type_group.map(&:short_code)).any?

    @manufacturers = Manufacturer.fetch_available(filters_type_group, filters_season).order(:name)
  end

  def filtered_page
    page_offset = (params[:page_id].to_i - 1).abs * APP_DEFINITIONS[:catalogue][:products_per_page].to_i
    products = get_products_by_filters(offset: page_offset)

    respond_to do |format|
      format.html do
        render partial: "products", locals: { products: products }
      end
    end
  end

  def details
    product = Size.find(params[:product_id])

    respond_to do |format|
      format.html do
        render partial: "product_details", locals: { product: product }
      end
    end
  end

  def request_cart
    unless cookies[:cart_items].blank?
      cart_items_array = Base64.decode64(cookies[:cart_items]).split(",")
      cart_items_hash = cart_items_array.each_with_object(Hash.new(0)) { |item_id, count| count[item_id] += 1 }

      products = cart_items_hash
        .transform_keys { |item_id| get_product(item_id) }
        .delete_if { |k, v| k.blank? }

      respond_to do |format|
        format.html do
          render partial: "request_cart", locals: { products: products }
        end
      end
    end
  end

  def send_inquiry
    CatalogueMailer.inquiry(params[:request]).deliver
    @order = Order.where(email: params[:request][:person][:email]).last
    @locale = params[:locale]
    filename = "#{@order.id}_rekins"
    pdf = render_to_string :pdf => "#{filename}.pdf",
                           :template => "catalogue_mailer/print.html.erb",
                           :lowquality => false,
                           :grayscale => false,
                           :zoom => 0.60,
                           layout: "pdf.html.erb"
    CatalogueMailer.client_inquiry(params[:request], @order, "#{filename}.pdf", pdf).deliver
    respond_to :js
  end

  private

  def get_banners(location)
    {
      top: Banner.active.language(params[:locale]).location(location).position("top").order("RAND()").first,
      bottom: Banner.active.language(params[:locale]).location(location).position("bottom").order("RAND()").first,
    }
  end

  def convert_season_to_id(season)
    case season
    when "summer" then Model::SUMMER
    when "winter" then Model::WINTER
    when "mixed" then Model::MS
    else nil
    end
  end

  def get_product(product_id)
    Size.joins(:ipc).merge(Ipc.with_sell_price).published.find_by(id: product_id)
  end

  def get_all_products(offset: 0, limit: nil)
    limit ||= APP_DEFINITIONS[:catalogue][:products_per_page].to_i

    products = Size.published.joins(:usage, model: :manufacturer).includes(:usage, model: :manufacturer)
                   .where("`store_price` > 0")

    unless params[:only_bus].blank? or params[:only_bus] == "false"
      products = products.where(usages: { short_code: "BUS" })
    end

    unless params[:only_rft].blank? or params[:only_rft] == "false"
      additional_info_join_sql = <<-SQL
          LEFT JOIN `additional_infos` AS `first_additional_infos` ON `first_additional_infos`.`id` = `sizes`.`first_additional_info_id`
          LEFT JOIN `additional_infos` AS `second_additional_infos` ON `second_additional_infos`.`id` = `sizes`.`second_additional_info_id`
        SQL

      products = products.joins(additional_info_join_sql).where('`first_additional_infos`.`name` LIKE "%RFT%" OR `second_additional_infos`.`name` LIKE "%RFT%"')
    end

    unless params[:manufacturer_order].blank?
      manufacturer_order = params[:manufacturer_order] == "desc" ? "DESC" : "ASC"
      products = products.order("`manufacturers`.`name` #{manufacturer_order}")
    end

    price_order = params[:price_order] == "desc" ? :desc : :asc
    products.order("IFNULL(`sizes`.`store_sale_price`, 0) = 0")
            .order("IFNULL(`sizes`.`store_sale_price`, 0) #{price_order.upcase}")
            .order("IFNULL(COALESCE(NULLIF(`models`.`discount`, 0), NULLIF(`manufacturers`.`discount`, 0)), 0) = 0")
            .order("ROUND(`sizes`.`store_price` - (`sizes`.`store_price` * (COALESCE(NULLIF(`models`.`discount`, 0), NULLIF(`manufacturers`.`discount`, 0)) / 100)), 2) #{price_order.upcase}")
            .order(store_price: price_order)
            .limit(limit)
            .offset(offset)
  end

  def get_products_by_filters(offset: 0, limit: nil)
    limit ||= APP_DEFINITIONS[:catalogue][:products_per_page].to_i

    products = Size.published.joins(:usage, model: :manufacturer)
      .includes(:usage, model: :manufacturer)

    current_date = Date.today
    summer_season = (Date.new(current_date.year, 5, 1)..Date.new(current_date.year, 12, 1))
    current_season = summer_season.cover?(current_date) ? "summer" : "winter"

    complect_availability_filter = Ipc.full_complect_availability

    unless params[:type].blank?
      params[:type] = "car" unless params[:type].present? and Usage.exists?(short_code: params[:type].upcase)
      filters_type = Usage.find_by_short_code(params[:type].upcase)

      filters_type_group = []

      if filters_type.parent.present?
        filters_type_group << filters_type.parent
        filters_type_group += filters_type.parent.children.try(&:active).to_a
      else
        filters_type_group << filters_type
        filters_type_group += filters_type.children.try(&:active).to_a
      end

      params[:season] = current_season unless %w[summer winter mixed].include?(params[:season])
      filters_season = convert_season_to_id(params[:season])
      filters_season = [Model::WINTER, Model::MS] if filters_season == Model::WINTER
      if (%w[MOTO MOTOCROSS] & filters_type_group.map(&:short_code)).any?
        filters_season = nil
        complect_availability_filter = Ipc.minimum_complect_availability
      end

      products = products.where(usage: filters_type_group)
      products = products.where(models: { season: filters_season }) unless filters_season.blank?
      products = products.where(models: { manufacturer_id: params[:manufacturer] }) unless params[:manufacturer].blank?

      params[:data] = {}
      params[:data][:widths] = Size.fetch_available_widths(filters_type_group, filters_season)

      params[:width] = params[:data][:widths].first unless params[:width].present?

      params[:data][:heights] = Size.fetch_available_heights(filters_type_group, filters_season, params[:width])
      params[:data][:diameters] = Size.fetch_available_diameters(filters_type_group, filters_season, params[:width], params[:height])

      products = products.where(tire_width: params[:width])
      products = products.where(aspect_ratio: params[:height]) unless params[:height].blank?
      products = products.where(wheel_diameter: params[:diameter]) unless params[:diameter].blank?

      products = products.order("`usages`.`short_code` = '#{params[:type].upcase}' DESC")
                         .order("`usages`.`short_code`")
    end

    unless params[:only_bus].blank? or params[:only_bus] == "false"
      products = products.where(usages: { short_code: "BUS" })
    end

    unless params[:only_rft].blank? or params[:only_rft] == "false"
      additional_info_join_sql = <<-SQL
          LEFT JOIN `additional_infos` AS `first_additional_infos` ON `first_additional_infos`.`id` = `sizes`.`first_additional_info_id`
          LEFT JOIN `additional_infos` AS `second_additional_infos` ON `second_additional_infos`.`id` = `sizes`.`second_additional_info_id`
        SQL

      products = products.joins(additional_info_join_sql).where('`first_additional_infos`.`name` LIKE "%RFT%" OR `second_additional_infos`.`name` LIKE "%RFT%"')
    end

    @total = products.count

    unless params[:manufacturer_order].blank?
      manufacturer_order = params[:manufacturer_order] == "desc" ? "DESC" : "ASC"
      products = products.order("`manufacturers`.`name` #{manufacturer_order}")
    end

    price_order = params[:price_order] == "desc" ? :desc : :asc
    products.limit(limit)
      .offset(offset)
      .includes(:ipc)
      .merge(Ipc.with_sell_price)
      .merge(complect_availability_filter)
      .order("ipcs.sell_price #{price_order}")
  end

  def get_products_for_sale
    products = Size.published.joins(:usage, model: :manufacturer).includes(:usage, model: :manufacturer)
                   .where("`store_sale_price` > 0")

    unless params[:only_bus].blank? or params[:only_bus] == "false"
      products = products.where(usages: { short_code: "BUS" })
    end

    unless params[:only_rft].blank? or params[:only_rft] == "false"
      additional_info_join_sql = <<-SQL
          LEFT JOIN `additional_infos` AS `first_additional_infos` ON `first_additional_infos`.`id` = `sizes`.`first_additional_info_id`
          LEFT JOIN `additional_infos` AS `second_additional_infos` ON `second_additional_infos`.`id` = `sizes`.`second_additional_info_id`
        SQL

      products = products.joins(additional_info_join_sql).where('`first_additional_infos`.`name` LIKE "%RFT%" OR `second_additional_infos`.`name` LIKE "%RFT%"')
    end

    unless params[:manufacturer_order].blank?
      manufacturer_order = params[:manufacturer_order] == "desc" ? "DESC" : "ASC"
      products = products.order("`manufacturers`.`name` #{manufacturer_order}")
    end

    price_order = params[:price_order] == "desc" ? :desc : :asc
    products.order(store_sale_price: price_order, store_price: price_order)
  end

  def get_products_for_comparison
    compare_product_ids = Base64.decode64(cookies[:compare_items] || "").split(",")

    products = Size.published.joins(:usage, model: :manufacturer).includes(:usage, model: :manufacturer)
                   .where(id: compare_product_ids)

    unless params[:only_bus].blank? or params[:only_bus] == "false"
      products = products.where(usages: { short_code: "BUS" })
    end

    unless params[:only_rft].blank? or params[:only_rft] == "false"
      additional_info_join_sql = <<-SQL
          LEFT JOIN `additional_infos` AS `first_additional_infos` ON `first_additional_infos`.`id` = `sizes`.`first_additional_info_id`
          LEFT JOIN `additional_infos` AS `second_additional_infos` ON `second_additional_infos`.`id` = `sizes`.`second_additional_info_id`
        SQL

      products = products.joins(additional_info_join_sql).where('`first_additional_infos`.`name` LIKE "%RFT%" OR `second_additional_infos`.`name` LIKE "%RFT%"')
    end

    unless params[:manufacturer_order].blank?
      manufacturer_order = params[:manufacturer_order] == "desc" ? "DESC" : "ASC"
      products = products.order("`manufacturers`.`name` #{manufacturer_order}")
    end

    price_order = params[:price_order] == "desc" ? :desc : :asc
    products.order("IFNULL(`sizes`.`store_sale_price`, 0) = 0")
            .order("IFNULL(`sizes`.`store_sale_price`, 0) #{price_order.upcase}")
            .order("IFNULL(COALESCE(NULLIF(`models`.`discount`, 0), NULLIF(`manufacturers`.`discount`, 0)), 0) = 0")
            .order("ROUND(`sizes`.`store_price` - (`sizes`.`store_price` * (COALESCE(NULLIF(`models`.`discount`, 0), NULLIF(`manufacturers`.`discount`, 0)) / 100)), 2) #{price_order.upcase}")
            .order(store_price: price_order)
  end
end
```
