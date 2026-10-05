# frozen_string_literal: true
# Core Comments treats every `depth` method as a comment nesting depth.
class RenameTextworkHeadingDepth < ActiveRecord::Migration[7.2]
  def change
    rename_column :decidim_textwork_blocks, :depth, :heading_depth
  end
end
