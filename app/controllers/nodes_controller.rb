class NodesController < ApplicationController
  include NodesHelper
  include NewsHelper

  decorates_assigned :node
  decorates_assigned :menu_nodes, with: NodeDecorator

  def show
    @node = Node.find_by_path! params[:path] || ''
    raise ActiveRecord::RecordNotFound unless can? :read_public, @node
    @section = @node.section

    if @section
      @news = news_articles(section: @section).limit(3)
    end

    set_menu_nodes
    if bustable_stale?([@node, @section, *@news, *@ministers, *@departments, *@agencies, *@categories])
      render_node node
    end
  end

  def home
    @news = news_articles.limit(8)
    @ministers = Minister.all
    @departments = Department.all
    @agencies = Agency.all
    @categories = STATIC_DATA[:categories] #TODO Replace once categories are proper data
    show
  end

  def preview
    @node = Node.find_by_token!(params[:token])
    @section = @node.section
    set_menu_nodes
    render_node node
  end
end
