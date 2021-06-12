require 'prawn'
require 'prawn/table'

module Receipts
  class Invoice < Prawn::Document
    attr_reader :attributes, :id, :company, :custom_font, :line_items, :logo, :message, :product, :subheading, :bill_to, :issue_date, :due_date, :status, :outer_box, :inner_box, :main_font_size

    def initialize(attributes)
      @attributes     = attributes
      @id             = attributes.fetch(:id)
      @company        = attributes.fetch(:company)
      @line_items     = attributes.fetch(:line_items)
      @custom_font    = attributes.fetch(:font, {})
      @main_font_size = attributes.fetch(:main_font_size, 12)
      @message        = attributes.fetch(:message) { default_message }
      @subheading     = attributes.fetch(:subheading) { default_subheading }
      @bill_to        = Array(attributes.fetch(:bill_to)).join("\n")
      @issue_date     = attributes.fetch(:issue_date)
      @due_date       = attributes.fetch(:due_date)
      @status         = attributes.fetch(:status)
      @outer_box      = attributes.fetch(:outer_box) { default_outer_box }
      @inner_box      = attributes.fetch(:inner_box) { default_inner_box }

      super(margin: 0)

      setup_fonts if custom_font.any?
      generate
    end

    private

      def default_message
        "For questions, contact us anytime at <color rgb='326d92'><link href='mailto:#{company.fetch(:email)}'><b>#{company.fetch(:email)}</b></link></color>."
      end

      def default_subheading
        "INVOICE #%{id}"
      end
    
      def small_font_size
        (main_font_size * 0.8).round
      end
    
      def default_outer_box
        { width: 612, height: 792 }
      end
    
      def default_inner_box
        { width: 442, height: 622 }
      end
    
      def margin_width
        (outer_box[:width] - inner_box[:width]) / 2
      end
    
      def margin_height
        (outer_box[:height] - inner_box[:height]) / 2
      end

      def half_width
        inner_box[:width] / 2
      end

      def setup_fonts
        font_families.update "Primary" => custom_font
        font "Primary"
      end

      def generate
        bounding_box [0, outer_box[:height]], width: outer_box[:width], height: outer_box[:height] do
          bounding_box [margin_width, outer_box[:height]], width: inner_box[:width], height: outer_box[:height] do
            header
            charge_details
            footer
          end
        end
      end

      def header
        move_down margin_height

        logo = company[:logo]

        if logo.nil?
          move_down 48
        elsif logo.is_a?(String)
          image open(logo), height: 48
        else
          image logo, height: 48
        end

        move_down 32

        # Cache the Y value so we can have both boxes at the same height
        top = y
        bounding_box([0, y], width: half_width) do
          label "INVOICE NO."

          move_down 4
          text id, inline_format: true, size: main_font_size, leading: 4

          move_down 16
          label "BILL TO"

          move_down 4
          text_box bill_to, at: [0, cursor], width: half_width, height: 75, inline_format: true, size: main_font_size, leading: 4, overflow: :shrink_to_fit

        end

        bounding_box([half_width + 12, top], width: half_width - 12) do
          label "INVOICE DATE"

          move_down 4
          text issue_date.to_s, inline_format: true, size: main_font_size, leading: 4

          move_down 16
          label "DUE DATE"

          move_down 4
          text due_date.to_s, inline_format: true, size: main_font_size, leading: 4

          move_down 16
          label "STATUS"

          move_down 4
          text status, inline_format: true, size: main_font_size, leading: 4
        end
      end

      def charge_details
        move_down 32

        borders = line_items.length - 2

        table(line_items, width: bounds.width, cell_style: { size: main_font_size, border_color: 'cccccc', inline_format: true }) do
          cells.padding = 12
          cells.borders = []
          row(0..borders).borders = [:bottom]
        end
      end

      def footer
        move_down 32
        text message, inline_format: true, size: main_font_size, leading: 4

        move_down 24
        text company.fetch(:name), inline_format: true, size: main_font_size, leading: 4
        text "<color rgb='888888'>#{company.fetch(:address)}</color>", size: small_font_size, inline_format: true, leading: 4
      end

      def label(text)
        text "<color rgb='a6a6a6'>#{text}</color>", inline_format: true, size: small_font_size, leading: 4
      end
  end
end
