require 'prawn'
require 'prawn/table'

module Receipts
  class Receipt < Prawn::Document
    attr_reader :attributes, :id, :company, :custom_font, :line_items, :logo, :message, :product, :subheading, :outer_box, :inner_box, :main_font_size

    def initialize(attributes)
      @attributes     = attributes
      @id             = attributes.fetch(:id)
      @company        = attributes.fetch(:company)
      @line_items     = attributes.fetch(:line_items)
      @custom_font    = attributes.fetch(:font, {})
      @message        = attributes.fetch(:message) { default_message }
      @subheading     = attributes.fetch(:subheading) { default_subheading }
      @outer_box      = attributes.fetch(:outer_box) { default_outer_box }
      @inner_box      = attributes.fetch(:inner_box) { default_inner_box }
      @main_font_size = attributes.fetch(:main_font_size, 12)

      super(margin: 0)

      setup_fonts if custom_font.any?
      generate
    end

    private

      def default_message
        "We've received your payment for #{attributes.fetch(:product)}. You can keep this receipt for your records. For questions, contact us anytime at <color rgb='326d92'><link href='mailto:#{company.fetch(:email)}'><b>#{company.fetch(:email)}</b></link></color>."
      end

      def default_subheading
        "RECEIPT FOR CHARGE #%{id}"
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
        text "<color rgb='a6a6a6'>#{subheading % { id: id }}</color>", inline_format: true, size: main_font_size, leading: 4

        move_down 16
        text message, inline_format: true, size: main_font_size, leading: 4
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
        text company.fetch(:name), inline_format: true, size: main_font_size, leading: 4
        text "<color rgb='888888'>#{company.fetch(:address)}</color>", size: small_font_size, inline_format: true, leading: 4
      end
  end
end
