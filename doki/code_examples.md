# **EdCordata** - Some code examples
These are just some examples of code in my presonal projects.

### Folder Structure Example:
This is how I like to organize models so that, when opening
the models folder, I’m not greeted with 100+ files all at once.
```
app/
└── models/
    ├── association_tables/
    │   ├── order/
    │   │   └── order_product.rb
    │   └── product/
    │       ├── product_image.rb
    │       └── product_price.rb
    ├── concerns/
    │   └── users/
    │       ├── setup_email.rb
    │       ├── setup_password.rb
    │       └── setup_role.rb
    ├── conjunction_models/
    │   └── product/
    │       └── product_tag.rb
    ├── user.rb
    ├── tag.rb
    └── product.rb
```

### Code Styling Example:
This is how I prefer to structure and write code in projects
I when defining style guides.

```javascript
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require underscore
//
//= require nested_form_fields
//= require dependent-fields
//
//= require moment
//= require bootstrap-sprockets
//= require bootstrap-material-datetimepicker/init
//
//= require js-string/init
//
//= require_self
//
//= require_tree ./objects

window.init = {};

$(document).on('turbolinks:load', function () {
  init.dependentFields();
  init.dateTimePicker();
  init.select2();
});

$(document).on('fields_added.nested_form_fields', function (e) {
  init.dependentFields();
  init.dateTimePicker();
  init.select2();
});

$(window).on('resize', function () {
  init.select2();
});
```


```scss
//= require_self
//
//= require bootstrap/init
//= require bootstrap/btn-xs
//= require bootstrap/themes/material
//= require bootstrap-material-datetimepicker/init
//
//= require font-awesome
//= require css-spaces/init
//
//= require_tree ./pages
```

```ruby
class User < ApplicationRecord
  extend ::Enumerize

  include ::GenerateHashId
  include ::Versionable
  include ::AASM

  include ::Users::SetupEmail
  include ::Users::SetupLocale
  include ::Users::SetupDeleted
  include ::Users::SetupBlocked
  include ::Users::SetupPassword

  scope :valid, -> { where(deleted: false, blocked: false) }
end
```

```ruby
class Product < ApplicationRecord
  include ::GenerateHashId
  include ::SetupDeleted
  include ::SetupVisible


  # associations
  # ===========================================================================
  has_many :product_prices, dependent: :destroy
  has_many :product_images, dependent: :destroy
  has_many :cart_items,     dependent: :destroy

  accepts_nested_attributes_for :product_prices, allow_destroy: true
  accepts_nested_attributes_for :product_images, allow_destroy: true
  # ===========================================================================


  # scopes
  # ===========================================================================
  scope :valid, -> { not_deleted.visible }
  # ===========================================================================


  # uploaders
  # ===========================================================================
  mount_uploader :cover_image, ::ProductCoverImageUploader
  # ===========================================================================


  # translations
  # ===========================================================================
  translates :title, :desc,
             fallbacks_for_empty_translations: true

  globalize_accessors locales:    ::Settings['locales']['available'],
                      attributes: [:title, :desc]
  # ===========================================================================


  # instance methods
  # ===========================================================================

  def min_product_price
    self.product_prices.sort { |x| x.price_in_cents }.last
  end

  def max_product_price
    self.product_prices.sort { |x| x.price_in_cents }.first
  end

  # ===========================================================================


end
```

```ruby
class Admin::ProductsController < Admin::ApplicationController


  def index
    params[:q] ||= { deleted_eq: nil, visible_eq: true }

    @q = @permissions
          .records(:admin_products, :index, default: ::Product.none)
          .ransack(params[:q])

    @records = @q
                .result(distinct: true)
                .page(params[:page]).per(20)

    find_permitted_ids(
      ::Product.none,
      :admin_products, [:show, :edit, :delete, :destroy]
    )
  end


  def show
    @record = @permissions
                .records(:admin_products, :show, default: ::Product.none)
                .find(params[:id])

    find_permitted_ids(
      ::Product.none,
      :admin_products, [:show, :edit, :delete, :destroy],
      record: @record
    )
  end


  def new
    @record = ::Product.new
  end


  def create
    @record = ::Product.new

    if @record.update(product_params)
      redirect_to admin_product_path(@record.id)
    else
      render :new
    end
  end

  def edit
    @record = @permissions
                .records(:admin_products, :edit, default: ::Product.none)
                .find(params[:id])

    find_permitted_ids(
      ::Product.none,
      :admin_products, [:show, :edit, :delete, :destroy],
      record: @record
    )
  end


  def update
    @record = @permissions
                .records(:admin_products, :edit, default: ::Product.none)
                .find(params[:id])

    find_permitted_ids(
      ::Product.none,
      :admin_products, [:show, :edit, :delete, :destroy],
      record: @record
    )

    if @record.update(product_params)
      redirect_to admin_product_path(@record.id)
    else
      render :edit
    end
  end


  def delete
    @record = @permissions
                .records(:admin_products, :delete, default: ::Product.none)
                .find(params[:id])

    @record.update!(deleted: !@record.deleted)

    redirect_to params[:redirect_to] || admin_products_path
  end

  def destroy
    @record = @permissions
                .records(:admin_products, :destroy, default: ::Product.none)
                .find(params[:id])

    @record.destroy!

    redirect_to params[:redirect_to] || admin_products_path
  end


  private


  def product_params
    params.require(:product)
          .permit(@permissions.authorized_attributes(:admin_products, :params))
  end


end
```

```erb
<div class="card mt-20">
  <%= simple_form_for(@q, url: admin_products_path, method: :get, html: { class: 'search-form' }) do |f| %>

    <div class="card-header pt-12 pl-12">
      <strong><%= ::I18n.t('admin.views.shared.search') %></strong>
    </div>

    <div class="card-title p-12 pt-24">
      <div class="row">

        <div class="col-xs-12 col-sm-6 col-md-4">
          <%= f.input :hash_id_eq,
                      label:    ::I18n.t('activerecord.shared.hash_id'),
                      required: false %>
        </div>

        <div class="col-xs-12 col-sm-6 col-md-4">
          <%= f.input :translations_title_i_cont,
                      label:    ::I18n.t('activerecord.attributes.product.title'),
                      required: false %>
        </div>

        <div class="col-xs-12 col-sm-6 col-md-4">
          <%= f.input :deleted_eq,
                      label:         ::I18n.t('activerecord.shared.deleted'),
                      required:      false,
                      collection:    yes_no_search_collection,
                      input_html:    { class: 'js-select', 'data-search': 'false' },
                      include_blank: ::I18n.t('admin.views.shared.all') %>
        </div>

        <div class="col-xs-12 col-sm-6 col-md-4">
          <%= f.input :visible_eq,
                      label:         ::I18n.t('activerecord.shared.visible'),
                      required:      false,
                      collection:    yes_no_search_collection,
                      input_html:    { class: 'js-select', 'data-search': 'false' },
                      include_blank: ::I18n.t('admin.views.shared.all') %>
        </div>

      </div>
    </div>

    <div class="card-footer pl-12">
      <%= f.submit ::I18n.t('admin.views.shared.search'), class: 'btn btn-primary btn-sm' %>
      <%= link_to ::I18n.t('admin.views.shared.clear'), admin_products_path, class: 'btn btn-default btn-sm' %>
    </div>

  <% end %>
</div>

<div class="card mt-20">

  <div class="card-header pt-12 pl-12">
    <strong><%= ::I18n.t('admin.views.main_menu.products') %></strong>

    <div class="float-right">
      <% if @permissions.action?(:new, ::Admin::ProductsController) %>
        <%= link_to fa_icon('plus'), admin_product_new_path, class: 'btn btn-success' %>
      <% end %>
    </div>
  </div>

  <div class="card-title mb-0">
    <% if @records.length.zero? %>

      <div class="alert alert-info m-12">
        <%= ::I18n.t('admin.views.shared.no_records_found') %>
      </div>

    <% else %>

      <div class="table-responsive">
        <table class="table table-borderless table-striped mb-0">
          <thead>
            <tr>
              <th><%= sort_link @q, 'id',         ::I18n.t('activerecord.shared.id') %></th>
              <th><%= sort_link @q, 'title',      ::I18n.t('activerecord.attributes.product.title') %></th>
              <th><%=                             ::I18n.t('activerecord.associations.product.product_prices') %></th>
              <th><%=                             ::I18n.t('activerecord.attributes.product.cover_image') %></th>
              <th><%= sort_link @q, 'deleted',    ::I18n.t('activerecord.shared.deleted') %></th>
              <th><%= sort_link @q, 'visible',    ::I18n.t('activerecord.shared.visible') %></th>
              <th><%= sort_link @q, 'created_at', ::I18n.t('activerecord.shared.created_at') %></th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <% @records.each do |record| %>
              <tr data-deleted="<%= record.deleted.to_s %>" data-visible="<%= record.visible.to_s %>">
                <td><%= record.id %></td>
                <td><%= record.title %></td>
                <td><%= record.product_prices.map(&:to_s).join(', ') %></td>
                <td>
                  <% if record.cover_image.present? %>
                    <%= image_tag record.cover_image.url, style: 'max-width: 50px; max-height: 50px;' %>
                  <% end %>
                </td>
                <td><%= boolean_icon(record.deleted) %></td>
                <td><%= boolean_icon(record.visible) %></td>
                <td><%= record.created_at.to_s(:datetime) %></td>
                <td class="actions">
                  <%= render(partial: 'admin/products/partials/links', locals: { record: record }) %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>

    <% end %>
  </div>

  <% unless paginate(@records).blank? %>
    <div class="card-footer pt-26 pl-30">
      <%= paginate @records, theme: 'twitter-bootstrap-4' %>
    </div>
  <% end %>

</div>
```

```erb
<% unless action_name == 'index' %>
  <% if @permissions.action?(:index, ::Admin::ProductsController) %>
    <%= link_to fa_icon('list'), admin_products_path, class: 'btn btn-primary' %>
  <% end %>
<% end %>

<% unless action_name == 'show' %>
  <% if @permissions.action?(:show, ::Admin::ProductsController) %>
    <% if @permitted_ids_show&.include?(record.id) %>
      <%= link_to fa_icon('eye'), admin_product_path(record.id), class: 'btn btn-default' %>
    <% end %>
  <% end %>
<% end %>

<% unless %w[edit update].include?(action_name) %>
  <% if @permissions.action?(:edit, ::Admin::ProductsController) %>
    <% if @permitted_ids_edit&.include?(record.id) %>
      <%= link_to fa_icon('pencil'), admin_product_edit_path(record.id), class: 'btn btn-success' %>
    <% end %>
  <% end %>
<% end %>

<% if @permissions.action?(:delete, ::Admin::ProductsController) %>
  <% if @permitted_ids_delete&.include?(record.id) %>
    <%= link_to fa_icon('trash-o'), admin_product_delete_path(record.id), class: 'btn btn-danger' %>
  <% end %>
<% end %>

<% if @permissions.action?(:destroy, ::Admin::ProductsController) %>
  <% if @permitted_ids_destroy&.include?(record.id) %>
    <%= link_to fa_icon('trash-o'), admin_product_destroy_path(record.id), class: 'btn btn-dark' %>
  <% end %>
<% end %>
```
