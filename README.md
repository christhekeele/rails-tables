Rails-Tables
===========

A clean jQuery datatables DSL
-----------------------------

### Example: ###

#### app/assets/javascripts/application.js.coffee ####

    #QUICKSTART:

    #= require dataTables/jquery.dataTables
    #= require rails-tables
    
    # Standard datatables config goes here, with these three additions
    $ ->
        $('table.datatable').each ->
            $(@).dataTable
                # Look for a url in the data attributes of the table
                sAjaxSource: $(@).data('source')
                # Use initial page ordering specified in the datatable.rb file
                aoColumnDefs: window.rails_tables.columns
                fnServerParams: window.rails_tables.params

#### app/models/user.rb ####

    class User < ActiveRecord::Base

      #QUICKSTART:
      # This grants you use of User.datatable
      has_datatable

      #CUSTOMIZATION:
      # You can have multiple datatables by supplying a name. This is useful when you need to
      # expose the same dataset in very different contexts, with different fields.
      has_datatable :friends_datatable

      # Fields and so forth
    end


#### app/controllers/users_controller.rb ####

    class UsersController < ApplicationController

      #QUICKSTART:
      # For the most common usecase, you'll just want to give the table the view context and let it render.
      def index
        respond_to do |format|
          format.html
          format.json { render json: User.datatable.render_with(view_context) }
        end
      end

      #CUSTOMIZATION:
      # You can chain scopes that will apply to the dataset through lambdas.
      def paying_users
        respond_to do |format|
          format.html
          format.json {
            render json: User.datatable.render_with(
              view_context,
              scopes: [ lambda { |users| users.where('state = ?', :paying) } ]
            )
          }
        end
      end

      # Example usage of an entirely different datatable.
      # This example assumes a predefined friends_with scope on the User model.
      def friends
        @user = current_user
        respond_to do |format|
          format.html
          format.json { 
            render json: User.friends_datatable.render_with(
              view_context,
              scopes: [ lambda { |users| users.friends_with(@user) } ]
            )
          }
        end
      end

    end

#### app/views/users/index.html.haml ####

    #QUICKSTART:
    # Structure your table as you normally would, but supply your datatable's html_data.
    # Make sure your table headers match the number and order of columns as defined in your table/datatable.rb!

    %table#users.datatable{ data: User.datatable.html_data }
      %thead
        %tr
          %th ID
          %th Title
          %th Nickname
          %th Favorite Quote
          %th Username
          %th Employer
          %th Signed Up On
          %th Tier
          %th Actions

#### app/tables/users_datatable.rb ####

    class UsersDatatable < Datatable

      # Everything you want configurable about this table, wherever it appears on the site, is controlled here.
      # #{model.name.pluralize.camelize}Datatable is the expected name of this class, or
      # #{table_name.camelize} if you passed a custom name to your datatable.
      # The filepath to this class does not matter as long as it gets loaded into your rails environment.
      
      # If not specified here, you can always manually add the data-source attribute in the users/index.html,
      # instead of relying on User.datatable.html_data.
      self.source_path = :users_path

      # If not specified here, datatables will order :asc on the first column,
      # no matter how your dataset orders itself initially.
      # Setting this injects extra data attributes on pagethrough User.datatable.html_data that
      # override datatables behaviour, through the aoColumnDefs and fnServerParams javascripts.
      initial_ordering :username => :desc


      # The column DSL is a function that takes a hash with multiple options, as show below
      # (I'm experimenting with making it take blocks to clean things up right now)


      #QUICKSTART:
      # You can name the column anything you want.
      # A vanilla column will look for a method or attribute on the model with the same name.
      column :id


      #CUSTOMIZATION:
      # You can instead tell it to look for a different method or attribute on the model.
      column :title, :column_name => :official_sounding_title

      # By default, method calls that return nil on the model render as an ndash. You can change this.
      column :nickname, :blank_value => 'Not cool enough'

      # All columns are sortable by default. You can change this.
      column :favorite_quote, :sortable => false


      # You can use predefined render functions to change how the data appears on page:

      # :self_referential_link wraps the output in a link_to the object it is displaying
      column :username, :render_with => :self_referential_link

      # :related_link assumes the column is a relation to another object, and wraps that in a link_to
      # Sorting on related objects does not work yet, so be sure to mark the column as not sortable.
      column :employer, :column_name => :company, :render_with => :related_link, :sortable => :false

      # :time, :date, and :datetime render wrapping content in
      # "%I:%M%p", "%m/%d/%Y", and "%m/%d/%Y at %I:%M%p" patterns accordingly.
      column :signed_up_on, :column_name => :created_at, :render_with => :datetime


      # :render_with also accepts lambdas for custom results.
      # Each lambda recieves the view context and the object being placed on the table.
      # Whatever it returns is what gets placed on the column
      # This allows for great customization, styling, visual rendering, complicated logic,
      # and columns that have nothing to do with the database.
      # If your column does not exist in the database, you need to mark it as not sortable or rails-tables will break.
      # You are responsible for marking the output of the lambda as .html_safe.

      column :tier,
        render_with: lambda { |view, user|
          if user.state == 'paying'
            '<span class="icon">$</span>'
          elsif user.state == 'demoing'
            '<i class="icon-eye-open dim">'
          elsif user.state == 'unregistered'
            '<i class="icon-eye-close dim">'
          end
        }

      column :actions,
        sortable: false,
        render_with: lambda { |view, user|
          links = [
            view.link_to('<i class="icon-zoom-in"></i>'.html_safe, user_path, {class: 'btn btn-mini'}),
            view.link_to('<i class="icon-wrench"></i>'.html_safe, edit_user_path, {class: 'btn btn-mini'}),
            view.link_to('<i class="icon-remove"></i>'.html_safe, delete_user_path, {class: 'btn btn-mini'}),
          ]
          view.content_tag(:div, links.join(" ").html_safe, { class: 'btn-group inline-actions'})
        }