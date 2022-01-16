# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class ParagraphInputFilter < Decidim::Core::BaseInputFilter
      include Decidim::Core::HasPublishableInputFilter

      graphql_name "ParagraphFilter"
      description "A type used for filtering paragraphs inside a participatory space.

A typical query would look like:

```
  {
    participatoryProcesses {
      components {
        ...on Paragraphs {
          paragraphs(filter:{ publishedBefore: \"2020-01-01\" }) {
            id
          }
        }
      }
    }
  }
```
"
    end
  end
end
