module ImportableAttachments::Base
  module ClassMethods

    # :call-seq:
    # has_importable_attachment opts
    #
    # = opts
    #   :import_method
    #   :import_into
    #   :spreadsheet_columns

    def has_importable_attachment(options)
      lopt = {import_method: :import_rows}
      lopt.merge! options

      validate_importable_attachment_options lopt
      install_importable_attachment_options lopt
      install_importable_attachment_associations
      install_importable_attachment_validations
      install_importable_attachment_assignment_protection

      include InstanceMethods

      # for assigning attachment to new record
      after_create :import_attachment
    end

    def validate_importable_attachment_options(options)
      [:spreadsheet_columns, :import_into].each do |sym|
        raise RuntimeError, "has_importable_attachment: needs :#{sym}" unless options.has_key? sym
      end

      unless options[:spreadsheet_columns].is_a?(Enumerable)
        raise RuntimeError, 'has_importable_attachment: :spreadsheet_columns must be Enumerable'
      end
    end

    def install_importable_attachment_options(options)
      [:import_method, :import_into, :spreadsheet_columns].each do |sym|
        cattr_accessor sym
        self.send("#{sym}=".to_sym, options[sym])
      end
    end

    def install_importable_attachment_associations
      has_one :attachment, :dependent => :nullify, :as => :attachable
      delegate :io_stream, :to => :attachment, :prefix => true
      delegate :io_stream_url, :to => :attachment, :prefix => true
      delegate :io_stream_file_name, :to => :attachment, :prefix => true
    end

    def install_importable_attachment_validations
      validates :attachment, :associated => true
      validate do |record|
        if @columns_not_found
          invalid_attachment_error "column(s) not found: #{@columns_not_found}"
        end
        if !@row_errors.blank?
          invalid_attachment_error "failed to import #{@row_errors.length} record(s)"
          @row_errors.each {|row| attachment.errors.add(:base, row)}
        end
      end

      # These go in the class calling has_importable_attachment as they are
      # dependent on mime-type expectations
      #validates_with CsvValidator, :if => Proc.new {|model| model.attachment.present?}
      #validates_with ExcelValidator, :if => Proc.new {|model| model.attachment.present?}
    end

    def install_importable_attachment_assignment_protection
      attr_accessible :attachment, :attachment_attributes, :attachment_id
      accepts_nested_attributes_for :attachment, :allow_destroy => true,
        :reject_if => :all_blank
    end
  end

  module InstanceMethods
    # : call-seq:
    # import_attachment
    #
    # imports an attachment of a given mime-type (data-stream to ruby),
    # calls import_rows with a ruby data-store
    #
    # NOTE: this is a stub

    def import_attachment
      raise RuntimeError, '[importable_attachments] .import_attachment not implemented'
    end

    # : call-seq:
    # import_rows params
    #
    # imports an attachment contents into :import_into association
    #
    # NOTE: this is a stub

    def import_rows(*opts)
      return unless self.attachment
      logger.debug "[importable_attachments] .import_rows #{opts}"
      raise RuntimeError, '[importable_attachments] .import_rows not implemented'
    end

    def invalid_attachment_error(msg)
      attachment.errors.add(:base, msg)
      errors.add(:attachment, 'invalid attachment')
    end
  end
end
