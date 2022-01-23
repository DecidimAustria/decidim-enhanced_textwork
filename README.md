# Decidim::EnhancedTextwork

The EnhancedTextwork module allows users to contribute to a participatory process with text work by creating paragraphs.

This module is based on decidim-proposals and was developed to improve the existing participatory_texts functionality to better suite specific needs we found in Austria.

## Usage

EnhancedTextwork is available as a Component for a Participatory Process.

We also extended some javascript code using webpacker.

That means it needs at least **Decidim v0.25.0** to work.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'decidim-enhanced_textwork'
```

And then execute:

```bash
bundle
```

## Improvements

Within the scope of our project we improved a few parts of the feature called “participatory_text”, wich is part of the core module “decidim-proposals”.
Unfortunately after finishing our work the decidim core team in Barcelona did not have available resources to integrate our results in the decidim core. For this reason we created a new module based on “decidim-proposals” including our participatory_text enhancements.

We named the base model for participatory texts `Paragraph` (instead of Proposal).

Our improvements span 3 areas described in the following sections:

* [Participatory Text Frontend](#participatory-text-frontend)
* [Participatory Text Result Export](#participatory-text-result-export)
* [Participatory Text Import](#participatory-text-import)

### Participatory Text Frontend

To make working with a participatory text easier and more user friendly we rebuilt the design for the overview page and created a sidebar.

#### Sidebar

We called the page including the sidebar “overview” and added it to the routes of the proposals module:

[lib/decidim/enhanced_textwork/engine.rb](lib/decidim/enhanced_textwork/engine.rb#L21)

#### Comments

To change the style of the comments to better fit the sidebar and to improve user experience we created a new class `Decidim::EnhancedTextwork::CommentsCell` that derives from the global `Decidim::Comments::CommentsCell`.
That allowed us to overwrite the global comments cell view while still using most of the other views of the global `CommentsCell`.

* [comments_cell.rb](app/cells/decidim/enhanced_textwork/comments_cell.rb)
* [show.erb](app/cells/decidim/enhanced_textwork/comments/show.erb)


#### Adding component settings

We added a setting to allow hiding proposal titles, because numbered titles did not make sense for long texts. In our new module we enable this setting by default.

In Decidim every component (module) allows you to define settings that get then displayed automatically in the components edit view using the localized texts configured for example under `en.decidim.components.enhanced_textwork.settings.global.hide_participatory_text_titles_enabled`

```rb
settings.attribute :hide_participatory_text_titles_enabled, type: :boolean, default: true
```

[see component.rb](lib/decidim/enhanced_textwork/component.rb#L50)

## Participatory Text Result Export

Because `enhanced_textwork` is based on `proposals`, the `Paragraph` model is based on the `Proposal` model. For this reason all the features existing for proposals can also be used on enhanced_textwork. One of those features is the export of results. Until now exporting results was optimized for proposals and didn’t make a lot of sense for exporting the results of collaborative work on a big text document consisting of many sections.

Existing export formats for proposals were defined in [decidim-core](https://github.com/decidim/decidim/tree/develop/decidim-core/lib/decidim/exporters):

* CSV
* Excel
* JSON

We decided to add a new Word/docx export exclusively in the enhanced_textwork module:

[lib/decidim/exporters/word.rb](lib/decidim/exporters/word.rb)

To enable it, the export formats need to be defined in the component configuration:

[lib/decidim/proposals/component.rb](lib/decidim/enhanced_textwork/component.rb#L144)

To export in docx format we decided to use a more recent fork of the [caracal](https://github.com/commonlit/caracal) gem by commonlit.

## Participatory Text Import

To add a new page for importing text directly from a rich text editor we had to add some routes in the [admin_engine](lib/decidim/enhanced_textwork/admin_engine.rb#L33)

Decidim already uses the [quill](https://github.com/quilljs/quill) richt text editor in many places, so we decided to also use it.

We created a new [HtmlToMarkdown](lib/decidim/enhanced_textwork/html_to_markdown.rb) class that uses the [kramdown](https://github.com/gettalong/kramdown) gem to convert the html output of the quill editor to markdown, which is already the supported format for importing documents.

The new class had to be autoloaded from the [proposals component](lib/decidim/enhanced_textwork.rb#L21)

### Allow to delete single drafts

After importing text it was not possible to delete single proposals/paragraphs of the draft. You could only delete all proposals together.
Therefore we added a delete button to each draft and added a new [command](app/commands/decidim/enhanced_textwork/destroy_paragraph.rb) and a [destroy_draft controller action](app/controllers/decidim/enhanced_textwork/admin/paragraphs_controller.rb#L147) that we also added to the [routes in the admin_engine](lib/decidim/enhanced_textwork/admin_engine.rb#L25 ):

### Configuring Similarity

`pg_trgm` is a PostgreSQL extension providing simple fuzzy string matching used in the Paragraph wizard to find similar published paragraphs (title and the body).

Create config variables in your app's `/config/initializers/decidim-enhanced_textwork.rb`:

```ruby
Decidim::EnhancedTextwork.configure do |config|
  config.similarity_threshold = 0.25 # default value
  config.similarity_limit = 10 # default value
end
```

`similarity_threshold`(real): Sets the current similarity threshold that is used by the % operator. The threshold must be between 0 and 1 (default is 0.3).

`similarity_limit`: number of maximum results.

## Global Search

This module includes the following models to Decidim's Global Search:

- `Paragraphs`

## Participatory Texts

Participatory texts persist each section of the document in a Paragraph.

When importing participatory texts all formats are first transformed into Markdown and is the markdown that is parsed and processed to generate the corresponding Paragraphs.

When processing participatory text documents three kinds of secions are taken into account.

- Section: each "Title 1" in the document becomes a section.
- Subsection: the rest of the titles become subsections.
- Article: paragraphs become articles.

## Contributing

Feel free to use the issues and pull requests to contribute to this module.

## License

AGPL-3.0
