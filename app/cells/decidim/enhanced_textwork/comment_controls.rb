# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module CommentControls
      module Author
        private

        def render_template(template, render_options, &)
          return super unless render_options[:view].to_s == "avatar" && options[:textwork_initials]

          initials = strip_tags(display_name).split.first(2).map { |word| word.scan(/\X/).first }.join.upcase
          content_tag(:span, initials, class: "author__avatar-container tw-comment-initials", aria: { hidden: true })
        end

        def cache_hash
          options[:textwork_initials] ? "#{super}-textwork-initials" : super
        end
      end

      module Form
        def show
          output = super
          return output unless Participation.resource?(Participation.root(model))

          html = Nokogiri::HTML.fragment(output)
          field = html.at_css("textarea")
          if field
            label = Nokogiri::XML::Node.new("label", html.document)
            label["for"] = field["id"]
            label["class"] = "tw-comment-label"
            label.content = t("decidim.textwork.comment_form.#{reply? ? "reply_label" : "form_label"}")
            field.add_previous_sibling(label)
            field["aria-describedby"] = [field["aria-describedby"], "#{field["id"]}-remaining-characters"].compact.join(" ")
          end
          html.to_html.html_safe
        end

        def comment_as
          return if Participation.resource?(Participation.root(model))

          super
        end

        private

        def parse_html_options(options)
          parsed = super
          parsed[:data][:validate_on_blur] = false if Participation.resource?(Participation.root(model))
          parsed
        end

        def cache_hash
          Participation.resource?(Participation.root(model)) ? "#{super}-labelled-no-blur-validation" : super
        end
      end

      module List
        def can_add_comments?
          resource = Participation.root(model)
          return false if Participation.resource?(resource) && !resource.accepts_new_comments?

          super
        end

        private

        def render_template(template, render_options, &)
          output = super
          return output unless render_options[:view].to_s == "inline" && Participation.resource?(Participation.root(model))

          html = Nokogiri::HTML.fragment(output)
          html.at_css(".comments__header h2")&.name = "h3"
          html.to_html.html_safe
        end
      end

      module Comment
        def cell(name, model = nil, options = {})
          options = options.merge(textwork_initials: true) if name == "decidim/author" && Participation.resource?(root_commentable)
          super
        end

        def votes
          return if Participation.resource?(root_commentable) && !Participation.open?(root_commentable.component, :comments)

          super
        end

        private

        def cache_hash
          value = super
          Participation.resource?(root_commentable) ? "#{value}-initials-#{Participation.open?(root_commentable.component, :comments)}" : value
        end

        def can_reply?
          return false if Participation.resource?(root_commentable) && !root_commentable.accepts_new_comments?

          super
        end
      end
    end
  end
end
