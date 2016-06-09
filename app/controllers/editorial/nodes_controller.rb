module Editorial
  class NodesController < ::ApplicationController
    include ::NodesHelper

    before_action :load_lists, :derive_type, except: [:show, :prepare]

    def index
      authorize! :view, :editorial_page
      @section = Section.find_by slug: params[:section]
      @nodes = @section.nodes.order(updated_at: :desc).decorate
    end

    # TODO: show useful editorial things here rather than just showing the published version
    def show
      @node = Node.find(params[:id]).decorate
      @section = @node.section
      render_node @node, @section
    end

    def prepare
      @type = Node
      @form_type = NodeForm
      configure_defaults!

      @node_types = [GeneralContent, NewsArticle].collect do |clazz|
        name = clazz.name.underscore
        [I18n.t("domain_model.nodes.#{name}"), name]
      end

      @prompt = if @parent
        "below #{@parent.name}"
      else
        "in #{@section.name}"
      end
    end

    def new
      configure_defaults!
    end

    def create
      @form = new_form
      if try_save
        redirect_to editorial_node_path(@form)
      else
        render :new
      end
    end

    def edit
      @node = Node.find(params[:id])
      @type_name = @node.class.name.underscore
      @form = "#{@node.class.name}Form".constantize.new(@node)
    end

    def update
      @node = Node.find(params[:id])
      @form = new_form(@node)

      if try_save
       redirect_to editorial_node_path(@form)
      else
        render :edit
      end

    end

    private

    def load_lists
      @sections = Section.all
    end

    def derive_type
      @type_name = params[:type] || 'general_content'
      # Be extra pedantic with user input that is being turned into code
      raise 'Invalid type' unless %w{general_content news_article}.include?(@type_name)
      @type = @type_name.camelize.constantize
      @form_type = "#{@type.name}Form".constantize
    end

    def new_form(obj=nil)
      if obj
        @form_type.new(obj)
      else
        @form_type.new(@type.new(content_block: ContentBlock.new))
      end
    end

    def configure_defaults!
      @form = new_form
      @parent = Node.find(params[:parent]) if params[:parent].present? else nil

      @section = if @parent.present?
        @form.parent_id = @parent.id
        @parent.section
      elsif params[:section].present?
        Section.find params[:section]
      end

      @form.section_id = @section.id if @section.present?
    end

    def try_save
      return false unless @form.validate(params.require(:node).permit!)
      @form.sync
      @form.model.save
    end
  end
end