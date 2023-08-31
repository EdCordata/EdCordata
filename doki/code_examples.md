# **EdCordata** - Some code examples


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

  private

  def set_version
    self.version_body = {
      role:               self.role,
      email:              self.email,
      deleted:            self.deleted,
      blocked:            self.blocked,
      blocked_reason:     self.blocked_reason,
      encrypted_password: self.encrypted_password
    }
  end

end
```


```ruby
require 'active_support/concern'

module Users
  module SetupPermissions
    extend ::ActiveSupport::Concern

    included do


      delegate :can?, :cannot?, :to => :ability


      def ability
        @ability ||= ::Ability.new(self)
      end


      aasm column: :role do
        state :user, initial: true
        state :developer
      end


      enumerize :role,
                in:         ::I18n.t('enumerize.user.role').keys,
                i18n_scope: 'enumerize.user.role',
                predicates: { prefix: true }


    end
  end
end
```


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

/*
 z-index tracking
  #admin-links                                                                         - 14000
  .review-full-screen-wrap                                                             - 13000
  .search-bar-wrap .search-bar .query-wrap                                             - 11000
  *[data-highlighted="true"]                                                           - 10000
  .highlight-me-overlay                                                                - 9000
  .main-search-overlay                                                                 - 8500
  .buts-gallery-popup-plugin-wrap                                                      - 8300
  .auth-overlay                                                                        - 8200
  .question-overlay                                                                    - 8100
  #header                                                                              - 8000
  .cookies-agreement                                                                   - 8000
  .header-sub-menu                                                                     - 7700
  .ask-btn                                                                             - 7500
  .ask-btn                                                                             - 7500
  .header-auth-btns                                                                    - 7200
  #body                                                                                - 7000
  .root-page-cards-wrap                                                                - 7500
  body[data-controller="pages"][data-action="root"] .title-with-icon.large:first-child - 7500
  .js-slick                                                                            - 6000
  .js-slick-prev                                                                       - 6005
  .js-slick-next                                                                       - 6005
  .branch-select-overlay                                                               - 8200
  .city-page-main-wrap .branch-sector-select-wrap[data-toggled="true"] .menu           - 9000
  .branch-sector-select-wrap .menu .tabs-wrap ul li[data-active="true"] a:after        - 1100
  .branch-sector-select-wrap .menu .tabs-wrap ul:after                                 - 1000
  #footer
*/
```


```haml
.card.mt-20
  = simple_form_for(@q, url: admin_users_path, method: :get, html: {class: 'search-form'}) do |f|

    .card-header.pt-12.pl-12
      %strong= t('admin.views.shared.search')

    .card-title.p-12.pt-24
      .row

        .col-xs-12.col-sm-6.col-md-4
          = f.input :email_i_cont,
            label:         t('activerecord.attributes.user.email'),
            required:      false

        .col-xs-12.col-sm-6.col-md-2
          = f.input :role_eq,
            label:         t('activerecord.attributes.user.role'),
            required:      false,
            collection:    User.role.options,
            input_html:    {'data-js-select': '', 'data-search': 'true'},
            include_blank: t('admin.views.shared.all')

        .col-xs-12.col-sm-6.col-md-2
          = f.input :locale_eq,
            label:         t('activerecord.attributes.user.locale'),
            required:      false,
            collection:    User.locale.options,
            input_html:    {'data-js-select': '', 'data-search': 'true'},
            include_blank: t('admin.views.shared.all')

        .col-xs-12.col-sm-6.col-md-2
          = f.input :deleted_eq,
            label:         t('activerecord.shared.deleted'),
            required:      false,
            collection:    yes_no_search_collection,
            input_html:    {'data-js-select': '', 'data-search': 'false'},
            include_blank: t('admin.views.shared.all')

        .col-xs-12.col-sm-6.col-md-2
          = f.input :blocked_eq,
            label:         t('activerecord.attributes.user.blocked'),
            required:      false,
            collection:    yes_no_search_collection,
            input_html:    {'data-js-select': '', 'data-search': 'false'},
            include_blank: t('admin.views.shared.all')

    .card-footer.pl-12
      = f.submit t('admin.views.shared.search'), class: 'btn btn-primary btn-sm'
      = link_to  t('admin.views.shared.clear'), admin_users_path, class: 'btn btn-default btn-sm'


.card.mt-20

  .card-header.pt-12.pl-12
    %strong= t('admin.views.main_menu.users')

  .card-title.mb-0

    - if @users.length.zero?
      .alert.alert-info.m-12= t('admin.views.shared.no_records_found')

    - else
      .table-responsive
        %table.table.table-borderless.table-striped.mb-0.user-table
          %thead
            %tr
              %th= sort_link @q, 'id',         t('activerecord.shared.id')
              %th= sort_link @q, 'email',      t('activerecord.attributes.user.email')
              %th= sort_link @q, 'role',       t('activerecord.attributes.user.role')
              %th= sort_link @q, 'deleted',    t('activerecord.shared.deleted')
              %th= sort_link @q, 'blocked',    t('activerecord.attributes.user.blocked')
              %th= sort_link @q, 'created_at', t('activerecord.shared.created_at')
              %th
          %tbody
            - @users.each do |user|
              %tr{'data-deleted': user.deleted.to_s, 'data-blocked': user.blocked.to_s}
                %td= user.id
                %td= user.email
                %td= user.role.text
                %td= boolean_icon(user.blocked)
                %td= boolean_icon(user.deleted)
                %td= user.created_at.to_s(:datetime)
                %td.actions
                  = admin_login_as_user_link(user, icon_only: true)
                  = link_to fa_icon('eye'),    admin_user_path(user),      title: t('admin.views.shared.show'), class: 'btn btn-sm btn-default' if can?(:show, user)
                  = link_to fa_icon('pencil'), admin_edit_user_path(user), title: t('admin.views.shared.edit'), class: 'btn btn-sm btn-success' if can?(:edit, user)

  - unless paginate(@users).blank?
    .card-footer.pt-26.pl-30= paginate @users, theme: 'twitter-bootstrap-4'
```


```haml
= simple_form_for [:admin, @user] do |f|
  = f.input :id,           as: :display, required: false
  = f.input :email,        as: :display, required: false
  = f.input :locale,       as: :display, required: false
  = f.input :role,         as: :display, required: false
  = f.input :country_code, as: :display, required: false
  = f.input :city,         as: :display, required: false
  = f.input :is_driver,    as: :display, required: false
```
