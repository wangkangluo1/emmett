require 'emmett/document'
require 'emmett/renderer'

module Emmett
  class DocumentManager

    def self.render!(*args)
      new(*args).render!
    end

    def initialize(root_path)
      @root_path = root_path
      @index_path = File.join(root_path, 'api.md')
      @inner_path = File.join(root_path, 'api')
    end

    def index_document
      @index_document ||= render_path(@index_path)
    end

    def inner_documents
      @inner_documents ||= begin
        Dir[File.join(@inner_path, "**/*.md")].map do |path|
          render_path path
        end
      end
    end

    def inner_links
      @inner_links ||= inner_documents.map do |doc|
        {
          doc:      doc,
          title:    doc.title,
          short:    doc.short_name,
          link:     "./#{doc.short_name}.html",
          sections: doc.iterable_section_mapping
        }
      end.sort_by { |r| r[:title].downcase }
    end

    def render_index(renderer)
      render_document renderer, :index, index_document
    end

    def render_documents(renderer)
      inner_documents.each do |document|
        render_document renderer, :section, document
      end
    end

    def render(renderer)
      render_index renderer
      render_documents renderer
    end

    def render!
      p all_urls
      Renderer.new.tap do |renderer|
        renderer.prepare_output
        renderer.global_context = {css:   Pygments.css, links: inner_links}
        render renderer
      end
    end

    def all_urls
      out = inner_documents.inject({}) do |acc, current|
        acc[current.title] = current.http_requests.inject({}) do |ia, req|
          ia[req.section] ||= []
          ia[req.section] << req.request_line
          ia
        end
        acc
      end
    end

    private

    def render_document(renderer, template_name, document, context = {})
      puts "Rendering #{document.title}"
      renderer.render_to document.to_path_name, template_name, context.merge(content: document.highlighted_html)
    end

    def render_path(path)
      Document.from_path path
    end

  end
end