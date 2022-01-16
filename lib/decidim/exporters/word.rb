# frozen_string_literal: true

require "caracal"

module Decidim
  module Exporters
    # Exports any serialized object (Hash) into a readable Excel file. It transforms
    # the columns using slashes in a way that can be afterwards reconstructed
    # into the original nested hash.
    #
    # For example, `{ name: { ca: "Hola", en: "Hello" } }` would result into
    # the columns: `name/ca` and `name/es`.
    #
    # It will maintain types like Integers, Floats & Dates so Excel can deal with
    # them.
    class Word < Exporter
      # Public: Exports a file in an Excel readable format.
      #
      # Returns an ExportData instance.
      def export
        # @docx
        init_docx

        @component = collection.first.component
        @participatory_space = collection.first.participatory_space

        print_titles @component.name

        print_metadata

        print_descriptions collection.first.participatory_space

        collection.each do |paragraph|
          next if paragraph.amended.present?

          print_paragraph paragraph
        end

        # @docx.p collection.inspect

        doxc_buffer = @docx.render
        doxc_buffer.rewind
        ExportData.new(doxc_buffer.sysread, "docx")
      end

      private

      def init_docx
        @docx = Caracal::Document.new("export.docx")

        @docx.style id: "metadata", name: "Metadata" do
          color "929292"
        end

        @docx.style id: "gray", name: "Gray" do
          color "929292"
        end

        @docx.style id: "green", name: "Green" do
          color "61D836"
        end

        @docx.style id: "red", name: "Red" do
          color "EE220C"
        end
      end

      # def print_titles(titles)
      #   if titles.keys.count > 1
      #     titles.each do |language, name|
      #       @docx.h1 "#{language}: #{name}"
      #     end
      #   else
      #     @docx.h1 titles.values.first
      #   end
      # end

      def print_titles(titles, paragraph: nil, heading: "h1", description: "")
        description = "#{description}: " if description.present?

        if titles.keys.count > 1
          titles.each do |language, title|
            @docx.send(heading, "#{description}#{language}: #{title}") if show_title_for(paragraph, title)
          end
        elsif show_title_for(paragraph)
          @docx.send(heading, "#{description}#{titles.values.first}")
        end
      end

      def print_content(content, description: "")
        description = "#{description}: " if description.present?

        if content.keys.count > 1
          content.each do |language, body|
            @docx.p do
              text "#{description}#{language}:", bold: true if description.present?
              text body.to_s
            end
          end
        else
          @docx.p do
            text "#{description}:", bold: true if description.present?
            text content.values.first.to_s
          end
        end
      end

      def print_metadata
        metadata = [
          "ID",
          "participatory space id: #{@participatory_space.id}",
          "component id: #{@component.id}"
        ]
        @docx.p metadata.join(" | "), style: "metadata"
        @docx.p
      end

      def print_descriptions(participatory_space)
        participatory_space.short_description.each do |language, short_description|
          @docx.p "short description (#{language}): #{short_description}"
        end
        participatory_space.description.each do |language, description|
          @docx.p "description (#{language}): #{description}"
        end
      end

      def print_paragraph(paragraph)
        @docx.hr

        print_titles(paragraph.title, paragraph: paragraph, heading: "h2", description: "title")

        print_content(paragraph.body, description: "body")

        # possible states: not_answered evaluating accepted rejected withdrawn
        case paragraph.state
        when "accepted"
          @docx.p paragraph.state, bold: true, color: "61D836"
        when "evaluating", ""
          @docx.p paragraph.state, bold: true, color: "FFD932"
        when "rejected"
          @docx.p paragraph.state, bold: true, color: "EE220C"
        when "not_answered", "withdrawn"
          @docx.p paragraph.state, bold: true, color: "929292"
        end

        @docx.p "Reference: #{paragraph.reference}", style: "gray"
        @docx.p "Followers: #{paragraph.followers.count}", style: "gray"

        @docx.p do
          text "Supports: ", bold: true
          text paragraph.votes.count
        end

        @docx.p do
          text "endorsements/total_count: ", bold: true
          text paragraph.endorsements.count
        end

        @docx.p do
          text "comments: ", bold: true
          text paragraph.comments.count
        end

        @docx.p

        if paragraph.comments.any?
          @docx.h3 "Comments to this paragraph:"

          paragraph.comments.where(depth: 0).each do |comment|
            print_comment(comment)
          end

          @docx.p
        end

        @docx.h3 "Amendments:" if paragraph.amendments.any?

        paragraph.amendments.each do |amendment|
          print_amendment paragraph, amendment
        end
      end

      def print_amendment(paragraph, amendment)
        @docx.p "Amendment title: #{amendment.emendation.title.values.first}", bold: true if show_title_for(amendment.emendation)

        @docx.p amendment.emendation.body.values.first

        @docx.p do
          text "Amendment ID: ", bold: true
          text amendment.id
          text ", "
          text "Paragraph ID: ", bold: true
          text amendment.emendation.id
        end

        @docx.p do
          text "created: ", bold: true
          text amendment.created_at
        end

        @docx.p do
          text "author(s): ", bold: true
          text amendment.emendation.authors.collect { |a| "#{a.name} (#{a.id})" }.join(", ")
        end

        case amendment.amendable.state
        when "accepted"
          @docx.p amendment.amendable.state, bold: true, color: "61D836"
        when "evaluating", ""
          @docx.p amendment.amendable.state, bold: true, color: "FFD932"
        when "rejected"
          @docx.p amendment.amendable.state, bold: true, color: "EE220C"
        when "not_answered", "withdrawn"
          @docx.p amendment.amendable.state, bold: true, color: "929292"
        end

        @docx.p "Reference: #{paragraph.reference}", style: "gray"
        @docx.p "Followers: #{paragraph.followers.count}", style: "gray"

        @docx.p do
          text "Supports: ", bold: true
          text paragraph.votes.count
        end

        @docx.p do
          text "endorsements: ", bold: true
          text paragraph.endorsements.count
        end

        @docx.p do
          text "comments: ", bold: true
          text paragraph.comments.count
        end
      end

      def print_comment(comment)
        @docx.p do
          text " " * (comment.depth + 1)
          text "Body: ", bold: true
          text comment.body.values.first
        end

        @docx.p do
          text " " * (comment.depth + 1)
          text "ID: ", bold: true
          text comment.id
        end

        @docx.p do
          text " " * (comment.depth + 1)
          text "created: ", bold: true
          text comment.created_at
        end

        @docx.p do
          text " " * (comment.depth + 1)
          text "author: ", bold: true
          text "#{comment.author.name} (#{comment.author.id})"
        end

        @docx.p do
          text " " * (comment.depth + 1)
          text "alignment: ", bold: true
          case comment.alignment
          when 1
            text "in favor", color: "61D836"
          when 0
            text "neutral", color: "929292"
          when -1
            text "against", color: "EE220C"
          end
        end

        if comment.user_group.present?
          @docx.p do
            text " " * (comment.depth + 1)
            text "user-group id: ", bold: true
            text comment.decidim_user_group_id.to_s
          end

          @docx.p do
            text " " * (comment.depth + 1)
            text "user-group name: ", bold: true
            text comment.user_group.name
          end
        end

        # find comments to this comment and print them recursively
        Decidim::Comments::Comment.where(decidim_commentable_id: comment.id).each do |sub_comment|
          print_comment(sub_comment)
        end
      end

      def show_title_for(paragraph, title = "")
        return true unless paragraph.instance_of?(Decidim::EnhancedTextwork::Paragraph)

        !hide_title_for(paragraph, title)
      end

      def hide_title_for(paragraph, title = "")
        return false unless paragraph.instance_of?(Decidim::EnhancedTextwork::Paragraph)

        title = paragraph.title.values.first if title.blank?

        paragraph.component.settings.hide_participatory_text_titles_enabled? && title !~ /\D/
      end
    end
  end
end
