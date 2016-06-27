class Section < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :nodes
  # Make Section look like a node
  alias_attribute :children, :nodes

  validates :name, uniqueness: { case_sensitive: false }
  validates :slug, uniqueness: { case_sensitive: false }

  # Note: resourcify must be called in every subclass so rolify will work
  resourcify

  after_initialize :set_default_cms_type

  # Finds a node via path from this Section.
  def find_node!(path)
    path.split('/').reduce(self) do |node,slug|
      node.children.find_by! slug: slug
    end
  end

  # Finds the users with a role on this Section
  def users
    Section.find_roles.pluck(:name).inject(Array.new) do |result, role|
      result += User.with_role(role, self)
    end.uniq
  end

  def find_by_slug(slug)
    Section.find_by(slug: slug)
  end

  private

  def set_default_cms_type
    self.cms_type ||= "Collaborate"
  end
end
